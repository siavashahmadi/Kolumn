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

    static let all: [AppTheme] = [.lavenderMint, .peachSky, .lemonRose]
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
