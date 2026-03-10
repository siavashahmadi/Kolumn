import SwiftUI

struct ColumnView: View {
    let column: Column
    let viewModel: BoardViewModel
    @Environment(\.appTheme) private var theme
    @State private var isTargeted = false
    @State private var isRenaming = false
    @State private var renameText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ColumnHeaderView(column: column, viewModel: viewModel)

            Divider()

            ScrollView(.vertical) {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.sortedTasks(for: column)) { task in
                        TaskCardView(task: task, viewModel: viewModel)
                            .draggable(TaskDragPayload(taskID: task.id.uuidString))
                    }
                }
                .padding(10)
                .animation(.easeInOut(duration: 0.2), value: column.tasks.count)
            }
            .frame(maxHeight: .infinity)
        }
        .background(theme.columnHeaderColor.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isTargeted ? theme.accentColor : Color.clear,
                    lineWidth: 2
                )
                .animation(.easeInOut(duration: 0.15), value: isTargeted)
        )
        .contextMenu {
            Button("Rename Column") {
                renameText = column.title
                isRenaming = true
            }
            Divider()
            Button("Delete Column", role: .destructive) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.deleteColumn(column)
                }
            }
        }
        .dropDestination(for: TaskDragPayload.self) { payloads, _ in
            guard let payload = payloads.first else { return false }
            withAnimation(.easeInOut(duration: 0.25)) {
                viewModel.moveTask(withID: payload.taskID, to: column)
            }
            return true
        } isTargeted: { targeted in
            withAnimation(.easeInOut(duration: 0.15)) {
                isTargeted = targeted
            }
        }
        .alert("Rename Column", isPresented: $isRenaming) {
            TextField("Column name", text: $renameText)
            Button("Cancel", role: .cancel) { }
            Button("Rename") {
                let trimmed = renameText.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    viewModel.renameColumn(column, to: trimmed)
                }
            }
        }
    }
}
