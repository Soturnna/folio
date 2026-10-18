import Foundation
import Observation

/// Direção da virada de página.
enum PageTurn {
    case next
    case previous

    /// Caminho HTTP atendido pelo handler.sh no Kindle.
    var path: String { self == .next ? "/avancar" : "/voltar" }
}

/// Estado da conexão com o Kindle.
enum ConnectionState: Equatable {
    case notConfigured
    case checking
    case online(latencyMs: Int)
    case offline
}

/// Cérebro do app: guarda o endereço do Kindle, envia os comandos
/// e mantém os números da sessão de leitura.
/// É um objeto único (`shared`) para que a tela e os App Shortcuts
/// (Siri, botão de Ação, Toque traseiro) usem o mesmo estado.
@MainActor
@Observable
final class KindleController {
    static let shared = KindleController()

    private(set) var state: ConnectionState = .notConfigured
    private(set) var pagesThisSession = 0
    private(set) var sessionStart: Date?
    private(set) var lastAction: PageTurn?
    /// Aumenta a cada virada bem-sucedida; usado para disparar a vibração.
    private(set) var successCount = 0
    /// Aumenta a cada falha; usado para a vibração de erro.
    private(set) var failureCount = 0

    private let session: URLSession

    /// Avisado a cada virada (usado pelo controle de mídia para atualizar a tela bloqueada).
    var onTurn: ((Int) -> Void)?

    private init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 2.5
        config.timeoutIntervalForResource = 3
        config.waitsForConnectivity = false
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        session = URLSession(configuration: config)
        if host != nil { state = .checking }
    }

    // MARK: Endereço

    var host: String? {
        let value = UserDefaults.standard.string(forKey: SettingsKey.host) ?? ""
        return value.isEmpty ? nil : value
    }

    var port: Int {
        let value = UserDefaults.standard.integer(forKey: SettingsKey.port)
        return value == 0 ? SettingsDefaults.port : value
    }

    var addressDescription: String {
        guard let host else { return "Não configurado" }
        return "\(host):\(port)"
    }

    func configure(host: String, port: Int) {
        UserDefaults.standard.set(host, forKey: SettingsKey.host)
        UserDefaults.standard.set(port, forKey: SettingsKey.port)
        state = .checking
        Task {
            await ping()
            if LiveActivityManager.isEnabled { showLiveActivity() }
        }
    }

    private func url(for path: String) -> URL? {
        guard let host else { return nil }
        return URL(string: "http://\(host):\(port)\(path)")
    }

    // MARK: Comandos

    /// Envia uma virada de página. Devolve `true` se o Kindle confirmou.
    @discardableResult
    func turn(_ direction: PageTurn) async -> Bool {
        guard let url = url(for: direction.path) else {
            state = .notConfigured
            failureCount += 1
            return false
        }
        let started = Date()
        do {
            let (_, response) = try await session.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
            let ms = Int(Date().timeIntervalSince(started) * 1000)
            state = .online(latencyMs: ms)
            if sessionStart == nil { sessionStart = Date() }
            pagesThisSession = max(0, pagesThisSession + (direction == .next ? 1 : -1))
            lastAction = direction
            successCount += 1
            onTurn?(pagesThisSession)
            await LiveActivityManager.update(activityState(online: true))
            return true
        } catch {
            state = .offline
            failureCount += 1
            await LiveActivityManager.update(activityState(online: false))
            return false
        }
    }

    /// Verifica se o servidor do Kindle responde, sem virar página
    /// (o caminho "/" só devolve a página de controle).
    func ping() async {
        guard let url = url(for: "/") else {
            state = .notConfigured
            return
        }
        let started = Date()
        do {
            let (_, response) = try await session.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
            state = .online(latencyMs: Int(Date().timeIntervalSince(started) * 1000))
        } catch {
            state = .offline
        }
    }

    func resetSession() {
        pagesThisSession = 0
        sessionStart = nil
        lastAction = nil
        onTurn?(0)
        Task { await LiveActivityManager.update(activityState(online: state != .offline)) }
    }

    // MARK: Live Activity

    func activityState(online: Bool) -> FolioActivityAttributes.ContentState {
        FolioActivityAttributes.ContentState(
            pages: pagesThisSession,
            startedAt: sessionStart ?? Date(),
            online: online
        )
    }

    /// Mostra o painel da tela bloqueada (chamado com o app aberto).
    @discardableResult
    func showLiveActivity(force: Bool = false) -> String {
        if sessionStart == nil { sessionStart = Date() }
        let online: Bool
        if case .online = state { online = true } else { online = false }
        return LiveActivityManager.startIfNeeded(pages: pagesThisSession, startedAt: sessionStart ?? Date(), online: online, force: force)
    }
}
