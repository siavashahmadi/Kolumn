import Foundation
import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case light, dark, system
    var id: String { rawValue }
    var label: String {
        switch self {
        case .light: "Light"
        case .dark: "Dark"
        case .system: "System"
        }
    }
}

@Observable final class ThemeManager {
    var appearanceMode: AppearanceMode {
        didSet {
            UserDefaults.standard.set(appearanceMode.rawValue, forKey: "appearanceMode")
        }
    }

    var selectedLightThemeID: String {
        didSet {
            UserDefaults.standard.set(selectedLightThemeID, forKey: "selectedLightThemeID")
        }
    }

    var selectedDarkThemeID: String {
        didSet {
            UserDefaults.standard.set(selectedDarkThemeID, forKey: "selectedDarkThemeID")
        }
    }

    var systemColorScheme: ColorScheme = .light

    var activeTheme: AppTheme {
        let isDark: Bool
        switch appearanceMode {
        case .light: isDark = false
        case .dark: isDark = true
        case .system: isDark = systemColorScheme == .dark
        }

        if isDark {
            return AppTheme.darkThemes.first { $0.id == selectedDarkThemeID } ?? .darkLavender
        } else {
            return AppTheme.lightThemes.first { $0.id == selectedLightThemeID } ?? .lavenderMint
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch appearanceMode {
        case .light: .light
        case .dark: .dark
        case .system: nil
        }
    }

    init() {
        let savedMode = UserDefaults.standard.string(forKey: "appearanceMode") ?? "system"
        self.appearanceMode = AppearanceMode(rawValue: savedMode) ?? .system

        let savedLight = UserDefaults.standard.string(forKey: "selectedLightThemeID") ?? "lavender-mint"
        self.selectedLightThemeID = savedLight

        let savedDark = UserDefaults.standard.string(forKey: "selectedDarkThemeID") ?? "dark-lavender"
        self.selectedDarkThemeID = savedDark
    }
}
