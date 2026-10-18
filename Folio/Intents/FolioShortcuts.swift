import AppIntents

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
