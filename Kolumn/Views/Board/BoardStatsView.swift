import SwiftUI

struct BoardStatsView: View {
    let board: Board
    let viewModel: BoardViewModel
    @Environment(\.appTheme) private var theme

    private var allTasks: [TaskItem] {
        board.columns.flatMap(\.tasks)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Board Stats")
                .font(.headline)

            // Overview
            VStack(alignment: .leading, spacing: 6) {
                Text("Overview")
                    .font(.subheadline)
                    .foregroundStyle(theme.secondaryTextColor)
                StatRow(label: "Total Tasks", value: "\(allTasks.count)")
                StatRow(label: "Active", value: "\(allTasks.filter { !$0.isArchived }.count)")
                StatRow(label: "Archived", value: "\(allTasks.filter(\.isArchived).count)")
                StatRow(label: "Overdue", value: "\(overdueCount)", highlight: overdueCount > 0)
            }

            Divider()

            // By Priority
            VStack(alignment: .leading, spacing: 6) {
                Text("By Priority")
                    .font(.subheadline)
                    .foregroundStyle(theme.secondaryTextColor)
                ForEach(Priority.allCases) { priority in
                    let count = allTasks.filter { $0.priority == priority && !$0.isArchived }.count
                    StatRow(label: priority.label, value: "\(count)")
                }
            }

            Divider()

            // By Column
            VStack(alignment: .leading, spacing: 6) {
                Text("By Column")
                    .font(.subheadline)
                    .foregroundStyle(theme.secondaryTextColor)
                ForEach(viewModel.sortedColumns) { column in
                    let active = column.tasks.filter { !$0.isArchived }.count
                    StatRow(label: column.title, value: "\(active)")
                }
            }
        }
        .padding(16)
        .frame(width: 220)
    }

    private var overdueCount: Int {
        allTasks.filter { task in
            !task.isArchived && (task.dueDate.map { $0 < .now } ?? false)
        }.count
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
