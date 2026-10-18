import Foundation
import Observation

/// Um Kindle encontrado na rede.
struct DiscoveredKindle: Identifiable, Hashable {
    let host: String
    let port: Int
    let latencyMs: Int
    var id: String { "\(host):\(port)" }
}

/// Procura o servidor do Passador em todos os endereços da rede local.
///
/// Lógica: descobre o IP do iPhone (ex.: 192.168.3.20), pega os três
/// primeiros blocos (192.168.3) e testa do .1 ao .254 na porta 8080.
/// Um endereço só conta como Kindle se a resposta contiver o título
/// "Passador Kindle", que o handler.sh devolve.
@MainActor
@Observable
final class NetworkScanner {
    private(set) var isScanning = false
    private(set) var progress: Double = 0
    private(set) var found: [DiscoveredKindle] = []
    private(set) var localAddress: String?

    private var task: Task<Void, Never>?

    func start(port: Int = SettingsDefaults.port) {
        stop()
        found = []
        progress = 0
        localAddress = Self.wifiIPv4Address()
        guard let local = localAddress else { return }
        let parts = local.split(separator: ".")
        guard parts.count == 4 else { return }
        let prefix = parts.prefix(3).joined(separator: ".")
        isScanning = true

        task = Task { [weak self] in
            let config = URLSessionConfiguration.ephemeral
            config.timeoutIntervalForRequest = 0.9
            config.timeoutIntervalForResource = 1.2
            config.httpMaximumConnectionsPerHost = 1
            let session = URLSession(configuration: config)

            let hosts = (1...254).map { "\(prefix).\($0)" }.filter { $0 != local }
            let batchSize = 32
            var done = 0
            for batchStart in stride(from: 0, to: hosts.count, by: batchSize) {
                if Task.isCancelled { break }
                let batch = hosts[batchStart..<min(batchStart + batchSize, hosts.count)]
                let results = await withTaskGroup(of: DiscoveredKindle?.self) { group in
                    for host in batch {
                        group.addTask { await NetworkScanner.probe(host: host, port: port, session: session) }
                    }
                    var hits: [DiscoveredKindle] = []
                    for await hit in group { if let hit { hits.append(hit) } }
                    return hits
                }
                done += batch.count
                guard let self else { return }
                self.found.append(contentsOf: results)
                self.progress = Double(done) / Double(hosts.count)
            }
            self?.isScanning = false
            self?.progress = 1
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        isScanning = false
    }

    nonisolated private static func probe(host: String, port: Int, session: URLSession) async -> DiscoveredKindle? {
        guard let url = URL(string: "http://\(host):\(port)/") else { return nil }
        let started = Date()
        guard let (data, response) = try? await session.data(from: url),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let body = String(data: data, encoding: .utf8),
              body.contains("Passador Kindle") else { return nil }
        return DiscoveredKindle(host: host, port: port, latencyMs: Int(Date().timeIntervalSince(started) * 1000))
    }

    /// Lê o IPv4 da interface Wi-Fi (en0) usando a API de rede do sistema (getifaddrs).
    nonisolated static func wifiIPv4Address() -> String? {
        var pointer: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&pointer) == 0, let first = pointer else { return nil }
        defer { freeifaddrs(pointer) }
        var current: UnsafeMutablePointer<ifaddrs>? = first
        while let entry = current {
            let interface = entry.pointee
            if let addr = interface.ifa_addr,
               addr.pointee.sa_family == UInt8(AF_INET),
               String(cString: interface.ifa_name) == "en0" {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                if getnameinfo(addr, socklen_t(addr.pointee.sa_len), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                    return String(cString: hostname)
                }
            }
            current = interface.ifa_next
        }
        return nil
    }
}
