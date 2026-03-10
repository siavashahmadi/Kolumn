import SwiftUI

struct EmptyBoardView: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundStyle(theme.accentColor.opacity(0.6))

            Text("No Board Selected")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundStyle(theme.primaryTextColor)

            Text("Create a new board or select one from the sidebar to get started.")
                .font(.body)
                .foregroundStyle(theme.secondaryTextColor)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.backgroundColor)
    }
}
