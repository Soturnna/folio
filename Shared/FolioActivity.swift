import ActivityKit
import SwiftUI

/// Cores da marca usadas fora do app (Live Activity, controles),
/// onde o catálogo de cores do app não está disponível.
enum FolioPalette {
    static let amber = Color(red: 245 / 255, green: 177 / 255, blue: 76 / 255)
    static let onAmber = Color(red: 0.10, green: 0.07, blue: 0.02)
    static let success = Color(red: 48 / 255, green: 209 / 255, blue: 88 / 255)
    static let warning = Color(red: 1, green: 146 / 255, blue: 48 / 255)
}

/// Dados da Live Activity (painel da tela bloqueada e Dynamic Island).
/// `ContentState` é a parte que muda a cada página virada.
struct FolioActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var pages: Int
        var startedAt: Date
        var online: Bool
    }
}

/// Liga, atualiza e encerra a Live Activity.
@MainActor
enum LiveActivityManager {
    static var isEnabled: Bool {
        SettingsDefaults.bool(SettingsKey.liveActivity, default: true)
    }

    private static var activities: [Activity<FolioActivityAttributes>] {
        Activity<FolioActivityAttributes>.activities
    }

    /// Resultado da última tentativa, mostrado em Ajustes para diagnóstico.
    static var lastResult = "Ainda não tentou"

    /// Resumo do estado atual, para a linha "Estado do painel" em Ajustes.
    static var statusDescription: String {
        let auth = ActivityAuthorizationInfo()
        if !auth.areActivitiesEnabled { return "Bloqueado nos Ajustes do iPhone" }
        if let first = activities.first { return "Ativo (\(describe(first.activityState)))" }
        return lastResult
    }

    /// Cria o painel se ainda não existir. Só funciona com o app na tela
    /// (regra do iOS), por isso é chamado quando o app está aberto.
    @discardableResult
    static func startIfNeeded(pages: Int, startedAt: Date, online: Bool, force: Bool = false) -> String {
        guard isEnabled || force else {
            lastResult = "Desligado no Folio"
            return lastResult
        }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            lastResult = "Bloqueado nos Ajustes do iPhone"
            return lastResult
        }
        let state = FolioActivityAttributes.ContentState(pages: pages, startedAt: startedAt, online: online)
        if !activities.isEmpty {
            Task { await update(state) }
            lastResult = "Ativo"
            return lastResult
        }
        do {
            let activity = try Activity.request(
                attributes: FolioActivityAttributes(),
                content: ActivityContent(state: state, staleDate: nil),
                pushType: nil
            )
            lastResult = "Criado (\(describe(activity.activityState)))"
        } catch {
            lastResult = "Erro: \(error.localizedDescription) [\(String(describing: error))]"
        }
        return lastResult
    }

    private static func describe(_ state: ActivityState) -> String {
        switch state {
        case .active: "ativo"
        case .pending: "pendente"
        case .stale: "desatualizado"
        case .ended: "encerrado"
        case .dismissed: "dispensado"
        @unknown default: "desconhecido"
        }
    }

    static func update(_ state: FolioActivityAttributes.ContentState) async {
        for activity in activities {
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    static func endAll() async {
        for activity in activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
