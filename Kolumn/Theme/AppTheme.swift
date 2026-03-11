import SwiftUI

struct AppTheme: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let background: String
    let accent: String
    let cardBackground: String
    let primaryText: String
    let secondaryText: String
    let columnHeader: String

    var backgroundColor: Color { Color(hex: background) }
    var accentColor: Color { Color(hex: accent) }
    var cardBackgroundColor: Color { Color(hex: cardBackground) }
    var primaryTextColor: Color { Color(hex: primaryText) }
    var secondaryTextColor: Color { Color(hex: secondaryText) }
    var columnHeaderColor: Color { Color(hex: columnHeader) }

    static let lavenderMint = AppTheme(
        id: "lavender-mint",
        name: "Lavender & Mint",
        background: "#F5F0FF",
        accent: "#C3B1E1",
        cardBackground: "#E8F8F0",
        primaryText: "#3D3D3D",
        secondaryText: "#888888",
        columnHeader: "#EDE7FF"
    )

    static let peachSky = AppTheme(
        id: "peach-sky",
        name: "Peach & Sky",
        background: "#FFF5F0",
        accent: "#FFB3A7",
        cardBackground: "#E8F4FD",
        primaryText: "#3D3D3D",
        secondaryText: "#888888",
        columnHeader: "#FFE8E2"
    )

    static let lemonRose = AppTheme(
        id: "lemon-rose",
        name: "Lemon & Rose",
        background: "#FFFEF0",
        accent: "#FFE066",
        cardBackground: "#FFF0F5",
        primaryText: "#3D3D3D",
        secondaryText: "#888888",
        columnHeader: "#FFF9D6"
    )

    // MARK: - Dark themes

    static let darkLavender = AppTheme(
        id: "dark-lavender",
        name: "Dark Lavender",
        background: "#1A1625",
        accent: "#B39DDB",
        cardBackground: "#2D2540",
        primaryText: "#E8E0F0",
        secondaryText: "#9E93B0",
        columnHeader: "#241E35"
    )

    static let darkDefault = AppTheme(
        id: "dark-default",
        name: "Dark Slate",
        background: "#1C1C1E",
        accent: "#6CB4EE",
        cardBackground: "#2C2C2E",
        primaryText: "#E5E5E7",
        secondaryText: "#98989D",
        columnHeader: "#242426"
    )

    static let darkRose = AppTheme(
        id: "dark-rose",
        name: "Dark Rose",
        background: "#1E1518",
        accent: "#E8899E",
        cardBackground: "#2D2025",
        primaryText: "#F0E0E5",
        secondaryText: "#A08890",
        columnHeader: "#291C20"
    )

    static let lightThemes: [AppTheme] = [.lavenderMint, .peachSky, .lemonRose]
    static let darkThemes: [AppTheme] = [.darkLavender, .darkDefault, .darkRose]
    static let all: [AppTheme] = lightThemes + darkThemes
}

// MARK: - Color hex extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
