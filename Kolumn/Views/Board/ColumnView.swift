import SwiftUI

struct ColumnView: View {
    let column: Column
    let columnIndex: Int
    let viewModel: BoardViewModel
    @Environment(\.appTheme) private var theme
    @Environment(AppState.self) private var appState
    @State private var isTargeted = false
    @State private var isRenaming = false
    @State private var renameText = ""
    @State private var showColorPicker = false

    static let presetColors = [
        "#C3B1E1", "#FFB3A7", "#A7D8FF", "#B5EAD7", "#FFE066",
        "#FFD1DC", "#D4A5A5", "#A5C9CA", "#E8D5B7", "#B8B8D1"
    ]

    private var isColumnFocused: Bool {
        appState.selectedColumnIndex == columnIndex
    }

    var body: some View {
        let tasks = viewModel.sortedTasks(for: column)

        VStack(alignment: .leading, spacing: 0) {
            // Inline header
            HStack {
                Text(column.title)
                    .font(.headline)
                    .foregroundStyle(theme.primaryTextColor)
                Spacer()
                Text("\(tasks.count)")
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

            Divider()

            ScrollView(.vertical) {
                LazyVStack(spacing: 8) {
                    ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                        TaskCardView(task: task, viewModel: viewModel)
                            .draggable(TaskDragPayload(taskID: task.id.uuidString))
                            .dropDestination(for: TaskDragPayload.self) { payloads, _ in
                                guard let payload = payloads.first else { return false }
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    viewModel.moveTask(withID: payload.taskID, to: column, at: index)
                                }
                                return true
                            } isTargeted: { _ in }
                    }
                }
                .padding(10)
                .animation(.easeInOut(duration: 0.2), value: tasks.count)
            }
            .frame(maxHeight: .infinity)
        }
        .background(theme.columnHeaderColor.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isTargeted ? theme.accentColor : (isColumnFocused ? theme.accentColor.opacity(0.4) : Color.clear),
                    lineWidth: 2
                )
                .animation(.easeInOut(duration: 0.15), value: isTargeted)
                .animation(.easeInOut(duration: 0.15), value: isColumnFocused)
        )
        .contextMenu {
            Button("Rename Column") {
                renameText = column.title
                isRenaming = true
            }
            Button("Change Color") {
                showColorPicker = true
            }
            Divider()
            Button("Delete Column", role: .destructive) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.deleteColumn(column)
                }
            }
        }
        .popover(isPresented: $showColorPicker) {
            VStack(spacing: 8) {
                Text("Column Color")
                    .font(.headline)
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(28), spacing: 6), count: 5), spacing: 6) {
                    ForEach(Self.presetColors, id: \.self) { hex in
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.primary, lineWidth: column.colorHex == hex ? 2 : 0)
                            )
                            .onTapGesture {
                                viewModel.changeColumnColor(column, to: hex)
                                showColorPicker = false
                            }
                    }
                }
            }
            .padding(12)
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
