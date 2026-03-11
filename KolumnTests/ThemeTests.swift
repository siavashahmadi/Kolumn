import XCTest
import SwiftUI
@testable import Kolumn

final class ThemeTests: XCTestCase {

    override func setUp() {
        super.setUp()
        cleanUserDefaults()
    }

    override func tearDown() {
        cleanUserDefaults()
        super.tearDown()
    }

    // MARK: - Defaults

    func testDefaultAppearanceModeIsSystem() {
        let manager = ThemeManager()
        XCTAssertEqual(manager.appearanceMode, .system)
    }

    func testDefaultLightThemeIsLavenderMint() {
        let manager = ThemeManager()
        XCTAssertEqual(manager.selectedLightThemeID, "lavender-mint")
    }

    func testDefaultDarkThemeIsDarkLavender() {
        let manager = ThemeManager()
        XCTAssertEqual(manager.selectedDarkThemeID, "dark-lavender")
    }

    // MARK: - Active Theme Resolution

    func testActiveThemeLightMode() {
        let manager = ThemeManager()
        manager.appearanceMode = .light
        manager.selectedLightThemeID = "peach-sky"
        XCTAssertEqual(manager.activeTheme.id, "peach-sky")
    }

    func testActiveThemeDarkMode() {
        let manager = ThemeManager()
        manager.appearanceMode = .dark
        manager.selectedDarkThemeID = "dark-default"
        XCTAssertEqual(manager.activeTheme.id, "dark-default")
    }

    func testActiveThemeSystemModeUsesSystemScheme() {
        let manager = ThemeManager()
        manager.appearanceMode = .system
        manager.systemColorScheme = .dark
        manager.selectedDarkThemeID = "dark-rose"
        XCTAssertEqual(manager.activeTheme.id, "dark-rose")
    }

    func testActiveThemeSystemModeLightScheme() {
        let manager = ThemeManager()
        manager.appearanceMode = .system
        manager.systemColorScheme = .light
        manager.selectedLightThemeID = "lemon-rose"
        XCTAssertEqual(manager.activeTheme.id, "lemon-rose")
    }

    // MARK: - Fallbacks

    func testInvalidLightThemeIDFallback() {
        let manager = ThemeManager()
        manager.appearanceMode = .light
        manager.selectedLightThemeID = "nonexistent-theme"
        XCTAssertEqual(manager.activeTheme.id, "lavender-mint")
    }

    func testInvalidDarkThemeIDFallback() {
        let manager = ThemeManager()
        manager.appearanceMode = .dark
        manager.selectedDarkThemeID = "nonexistent-theme"
        XCTAssertEqual(manager.activeTheme.id, "dark-lavender")
    }

    // MARK: - Persistence

    func testAppearanceModePersists() {
        let manager = ThemeManager()
        manager.appearanceMode = .dark
        XCTAssertEqual(UserDefaults.standard.string(forKey: "appearanceMode"), "dark")
    }

    func testLightThemeIDPersists() {
        let manager = ThemeManager()
        manager.selectedLightThemeID = "peach-sky"
        XCTAssertEqual(UserDefaults.standard.string(forKey: "selectedLightThemeID"), "peach-sky")
    }

    func testDarkThemeIDPersists() {
        let manager = ThemeManager()
        manager.selectedDarkThemeID = "dark-default"
        XCTAssertEqual(UserDefaults.standard.string(forKey: "selectedDarkThemeID"), "dark-default")
    }

    func testCorruptedAppearanceModeInUserDefaults() {
        UserDefaults.standard.set("invalid_mode", forKey: "appearanceMode")
        let manager = ThemeManager()
        // Should fall back to .system since "invalid_mode" is not a valid AppearanceMode
        XCTAssertEqual(manager.appearanceMode, .system)
    }

    // MARK: - Preferred Color Scheme

    func testPreferredColorSchemeLight() {
        let manager = ThemeManager()
        manager.appearanceMode = .light
        XCTAssertEqual(manager.preferredColorScheme, .light)
    }

    func testPreferredColorSchemeDark() {
        let manager = ThemeManager()
        manager.appearanceMode = .dark
        XCTAssertEqual(manager.preferredColorScheme, .dark)
    }

    func testPreferredColorSchemeSystemNil() {
        let manager = ThemeManager()
        manager.appearanceMode = .system
        XCTAssertNil(manager.preferredColorScheme)
    }

    // MARK: - Theme Identity

    func testAllThemesHaveUniqueIDs() {
        let ids = AppTheme.all.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "All theme IDs should be unique")
    }

    func testThemeEquatable() {
        XCTAssertEqual(AppTheme.lavenderMint, AppTheme.lavenderMint)
        XCTAssertNotEqual(AppTheme.lavenderMint, AppTheme.peachSky)
        XCTAssertNotEqual(AppTheme.darkLavender, AppTheme.darkDefault)
    }
}
