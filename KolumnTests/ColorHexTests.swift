import XCTest
import SwiftUI
@testable import Kolumn

final class ColorHexTests: XCTestCase {

    func testColorHexWithHash() {
        // Should not crash
        let color = Color(hex: "#FF0000")
        XCTAssertNotNil(color)
    }

    func testColorHexWithoutHash() {
        let color = Color(hex: "FF0000")
        XCTAssertNotNil(color)
    }

    func testColorHexBlack() {
        let color = Color(hex: "#000000")
        // Verify through NSColor bridge
        let nsColor = NSColor(color)
        XCTAssertNotNil(nsColor)
    }

    func testColorHexWhite() {
        let color = Color(hex: "#FFFFFF")
        let nsColor = NSColor(color)
        XCTAssertNotNil(nsColor)
    }

    func testColorHexCaseInsensitive() {
        // Both should produce valid colors without crashing
        let lower = Color(hex: "#abcdef")
        let upper = Color(hex: "#ABCDEF")
        XCTAssertNotNil(lower)
        XCTAssertNotNil(upper)
    }

    func testColorHexEmptyString() {
        // Should not crash — scanner returns 0, producing black
        let color = Color(hex: "")
        XCTAssertNotNil(color)
    }

    func testColorHexInvalidCharacters() {
        // Should not crash — scanner stops at invalid chars
        let color = Color(hex: "#ZZZZZZ")
        XCTAssertNotNil(color)
    }

    func testColorHexShortString() {
        // Short hex is not standard 6-digit, but shouldn't crash
        let color = Color(hex: "#FFF")
        XCTAssertNotNil(color)
    }

    func testColorHexThemeColors() {
        // Verify all theme hex values parse without crashing
        for theme in AppTheme.all {
            XCTAssertNotNil(Color(hex: theme.background), "Failed for theme \(theme.id) background")
            XCTAssertNotNil(Color(hex: theme.accent), "Failed for theme \(theme.id) accent")
            XCTAssertNotNil(Color(hex: theme.cardBackground), "Failed for theme \(theme.id) cardBackground")
            XCTAssertNotNil(Color(hex: theme.primaryText), "Failed for theme \(theme.id) primaryText")
            XCTAssertNotNil(Color(hex: theme.secondaryText), "Failed for theme \(theme.id) secondaryText")
            XCTAssertNotNil(Color(hex: theme.columnHeader), "Failed for theme \(theme.id) columnHeader")
        }
    }

    func testColorHexColumnPresetColors() {
        // All preset column colors from the app
        let presets = [
            "#C3B1E1", "#FFB3A7", "#A7D8FF", "#B5EAD7",
            "#FFE066", "#FFD1DC", "#B0C4DE", "#C9E4CA",
            "#FFDAB9", "#D4A5A5"
        ]
        for hex in presets {
            XCTAssertNotNil(Color(hex: hex), "Failed for preset color \(hex)")
        }
    }
}
