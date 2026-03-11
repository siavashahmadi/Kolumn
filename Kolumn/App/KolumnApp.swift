import SwiftUI
import SwiftData

@main
struct KolumnApp: App {
    @State private var themeManager = ThemeManager()
    @State private var appState = AppState()
    @State private var notificationManager = NotificationManager()
    @Environment(\.colorScheme) private var colorScheme

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.appTheme, themeManager.activeTheme)
                .environment(themeManager)
                .environment(appState)
                .environment(notificationManager)
                .preferredColorScheme(themeManager.preferredColorScheme)
                .onChange(of: colorScheme) { _, newScheme in
                    themeManager.systemColorScheme = newScheme
                }
                .task {
                    themeManager.systemColorScheme = colorScheme
                    await notificationManager.requestPermission()
                }
        }
        .modelContainer(for: [Board.self, Column.self, TaskItem.self, Tag.self, Subtask.self])
        .defaultSize(width: 1200, height: 750)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Task") {
                    appState.triggerQuickAdd = true
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("New Board") {
                    appState.showNewBoardSheet = true
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
            CommandMenu("Tools") {
                Button("Command Palette") {
                    appState.isCommandPaletteOpen.toggle()
                }
                .keyboardShortcut("k", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
                .environment(themeManager)
                .environment(\.appTheme, themeManager.activeTheme)
                .preferredColorScheme(themeManager.preferredColorScheme)
        }
    }
}
