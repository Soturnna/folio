import Foundation

/// Chaves dos ajustes guardados no aparelho (UserDefaults).
/// Centralizar os nomes evita erros de digitação espalhados pelo código.
enum SettingsKey {
    static let host = "kindle.host"
    static let port = "kindle.port"
    static let volumeButtons = "ajuste.volume"
    static let haptics = "ajuste.vibracao"
    static let invert = "ajuste.inverter"
    static let keepAwake = "ajuste.telaLigada"
}

enum SettingsDefaults {
    static let port = 8080

    /// Valores iniciais na primeira abertura do app.
    static func register() {
        UserDefaults.standard.register(defaults: [
            SettingsKey.port: port,
            SettingsKey.volumeButtons: true,
            SettingsKey.haptics: true,
            SettingsKey.invert: false,
            SettingsKey.keepAwake: true
        ])
    }
}
