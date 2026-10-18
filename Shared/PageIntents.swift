import AppIntents

/// Ação "Avançar página": aparece na Siri, no Spotlight, no app Atalhos,
/// no botão de Ação, na Live Activity e nos controles da tela bloqueada.
///
/// Por que `LiveActivityIntent`: esse tipo de ação sempre roda dentro do
/// processo do APP (mesmo quando tocada no widget ou na tela bloqueada).
/// Assim ela usa o mesmo endereço do Kindle e o mesmo contador do app,
/// sem precisar de um "App Group" para compartilhar dados.
struct NextPageIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Avançar página"
    static var description = IntentDescription("Avança uma página no Kindle.")
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let ok = await KindleController.shared.turn(.next)
        let dialog: IntentDialog = ok ? "Página avançada." : "O Kindle não respondeu. Confira se o Passador está ligado."
        return .result(dialog: dialog)
    }
}

struct PreviousPageIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Voltar página"
    static var description = IntentDescription("Volta uma página no Kindle.")
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let ok = await KindleController.shared.turn(.previous)
        let dialog: IntentDialog = ok ? "Página anterior." : "O Kindle não respondeu. Confira se o Passador está ligado."
        return .result(dialog: dialog)
    }
}
