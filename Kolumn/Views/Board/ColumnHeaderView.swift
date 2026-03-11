import SwiftUI

struct ColumnHeaderView: View {
    let column: Column
    let viewModel: BoardViewModel
    @Environment(\.appTheme) private var theme

    var body: some View {
        HStack {
            Text(column.title)
                .font(.headline)
                .foregroundStyle(theme.primaryTextColor)

            Spacer()

            Text("\(column.tasks.count)")
                .font(.caption)
                .foregroundStyle(theme.secondaryTextColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(theme.accentColor.opacity(0.2))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                colors: [Color(hex: column.colorHex).opacity(0.35), Color(hex: column.colorHex).opacity(0.15)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}
