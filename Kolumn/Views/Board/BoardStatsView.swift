import SwiftUI

struct BoardStatsView: View {
    let board: Board
    let viewModel: BoardViewModel
    @Environment(\.appTheme) private var theme

    var body: some View {
        let activeTasks = board.columns.flatMap(\.tasks).filter { !$0.isArchived }
        let overdueCount = activeTasks.filter { $0.dueDate.map { $0 < .now } ?? false }.count

        VStack(alignment: .leading, spacing: 16) {
            Text("Board Stats")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                Text("Overview")
                    .font(.subheadline)
                    .foregroundStyle(theme.secondaryTextColor)
                StatRow(label: "Total Tasks", value: "\(activeTasks.count)")
                StatRow(label: "Overdue", value: "\(overdueCount)", highlight: overdueCount > 0)
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("By Priority")
                    .font(.subheadline)
                    .foregroundStyle(theme.secondaryTextColor)
                ForEach(Priority.allCases) { priority in
                    let count = activeTasks.filter { $0.priority == priority }.count
                    StatRow(label: priority.label, value: "\(count)")
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("By Column")
                    .font(.subheadline)
                    .foregroundStyle(theme.secondaryTextColor)
                ForEach(viewModel.sortedColumns) { column in
                    let count = viewModel.sortedTasks(for: column).count
                    StatRow(label: column.title, value: "\(count)")
                }
            }
        }
        .padding(16)
        .frame(width: 220)
    }
}

private struct StatRow: View {
    let label: String
    let value: String
    var highlight: Bool = false
    @Environment(\.appTheme) private var theme

    var body: some View {
        HStack {
            Text(label)
                .font(.callout)
                .foregroundStyle(theme.primaryTextColor)
            Spacer()
            Text(value)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundStyle(highlight ? .red : theme.accentColor)
        }
    }
}
