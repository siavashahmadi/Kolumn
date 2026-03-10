import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            ThemePickerView()
                .tabItem {
                    Label("Themes", systemImage: "paintpalette")
                }
        }
        .frame(width: 450, height: 300)
    }
}

struct GeneralSettingsView: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(spacing: 16) {
            Text("General Settings")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Kolumn")
                .font(.headline)

            Text("A native macOS Kanban board app built with SwiftUI and SwiftData.")
                .font(.body)
                .foregroundStyle(theme.secondaryTextColor)
                .multilineTextAlignment(.center)

            Spacer()

            Text("v1.0.0")
                .font(.caption)
                .foregroundStyle(theme.secondaryTextColor)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
