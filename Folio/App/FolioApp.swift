import SwiftUI

@main
struct FolioApp: App {
    init() {
        SettingsDefaults.register()
    }

    var body: some Scene {
        WindowGroup {
            RemoteView()
                .preferredColorScheme(.dark)
        }
    }
}
