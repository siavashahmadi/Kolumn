import SwiftUI
import SwiftData

@main
struct KolumnApp: App {
    @State private var themeManager = ThemeManager()
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.appTheme, themeManager.current)
                .environment(themeManager)
                .environment(appState)
        }
        .modelContainer(for: [Board.self, Column.self, TaskItem.self, Tag.self])
        .defaultSize(width: 1200, height: 750)

        Settings {
            SettingsView()
                .environment(themeManager)
                .environment(\.appTheme, themeManager.current)
        }
    }
}
