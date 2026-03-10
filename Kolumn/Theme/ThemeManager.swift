import Foundation

@Observable final class ThemeManager {
    var current: AppTheme {
        didSet {
            UserDefaults.standard.set(current.id, forKey: "selectedThemeID")
        }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "selectedThemeID") ?? "lavender-mint"
        self.current = AppTheme.all.first { $0.id == saved } ?? .lavenderMint
    }
}
