import SwiftUI

struct SidebarRowView: View {
    let board: Board
    @Environment(\.appTheme) private var theme

    var body: some View {
        HStack(spacing: 8) {
            Text(board.emoji)
                .font(.title3)
            Text(board.name)
                .font(.body)
                .foregroundStyle(theme.primaryTextColor)
                .lineLimit(1)
        }
        .padding(.vertical, 2)
    }
}
