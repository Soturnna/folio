import AppIntents

/// Ação "Avançar página": aparece na Siri, no Spotlight, no app Atalhos
/// e pode ser colocada no botão de Ação ou no Toque traseiro.
/// Roda sem abrir o app (openAppWhenRun = false).
struct NextPageIntent: AppIntent {
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

struct PreviousPageIntent: AppIntent {
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

/// App Shortcuts: ficam disponíveis assim que o app é instalado.
/// Cada frase precisa conter o nome do app.
struct FolioShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: NextPageIntent(),
            phrases: [
                "Próxima página no \(.applicationName)",
                "Avançar página no \(.applicationName)",
                "\(.applicationName) avançar"
            ],
            shortTitle: "Avançar página",
            systemImageName: "arrow.right"
        )
        AppShortcut(
            intent: PreviousPageIntent(),
            phrases: [
                "Voltar página no \(.applicationName)",
                "Página anterior no \(.applicationName)"
            ],
            shortTitle: "Voltar página",
            systemImageName: "arrow.left"
        )
    }
}
