import SwiftUI
import SwiftData

struct BoardView: View {
    let board: Board
    @Environment(\.appTheme) private var theme
    @Environment(ThemeManager.self) private var themeManager
    @Environment(AppState.self) private var appState
    @State private var viewModel: BoardViewModel
    @State private var showAddColumn = false
    @State private var showAddTask = false
    @State private var quickTaskTitle = ""
    @State private var showTaskDetail = false
    @State private var showStats = false
    @State private var isQuickAddFocused = false
    @FocusState private var isBoardFocused: Bool

    init(board: Board, modelContext: ModelContext) {
        self.board = board
        _viewModel = State(initialValue: BoardViewModel(board: board, modelContext: modelContext))
    }

    var body: some View {
        let columns = viewModel.sortedColumns

        GeometryReader { geo in
            let columnCount = columns.count
            let totalSpacing = CGFloat(max(columnCount - 1, 0)) * 12
            let padding: CGFloat = 20 * 2
            let availableWidth = geo.size.width - padding - totalSpacing
            let columnWidth = columnCount > 0
                ? max(220, min(320, availableWidth / CGFloat(columnCount)))
                : 280
            let needsScroll = columnWidth <= 220 && columnCount > 0

            ScrollView(needsScroll ? .horizontal : []) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(columns) { column in
                        ColumnView(
                            column: column,
                            columnIndex: columns.firstIndex(where: { $0.id == column.id }) ?? 0,
                            viewModel: viewModel
                        )
                        .frame(width: needsScroll ? 260 : columnWidth)
                    }
                }
                .padding(20)
                .frame(maxHeight: .infinity, alignment: .top)
            }
        }
        .background(
            LinearGradient(
                colors: [theme.backgroundColor, theme.accentColor.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .navigationTitle("\(board.emoji) \(board.name)")
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    ToolbarTextField(
                        placeholder: "Add task",
                        text: $quickTaskTitle,
                        isFocused: $isQuickAddFocused,
                        onSubmit: {
                            quickAddTask()
                            isBoardFocused = true
                        }
                    )
                    .frame(width: 200)

                    Button {
                        if quickTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                            showAddTask = true
                        } else {
                            quickAddTask()
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(theme.accentColor)
                            .padding(.horizontal, 6)
                    }
                    .buttonStyle(.plain)
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddColumn = true
                } label: {
                    Image(systemName: "plus.rectangle.on.rectangle")
                }
                .help("Add Column")
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    showStats.toggle()
                } label: {
                    Image(systemName: "chart.bar")
                }
                .help("Stats")
                .popover(isPresented: $showStats) {
                    BoardStatsView(board: board, viewModel: viewModel)
                }
            }
        }
        .sheet(isPresented: $showAddColumn) {
            AddColumnView(viewModel: viewModel)
        }
        .sheet(isPresented: $showAddTask) {
            AddTaskPopoverView(viewModel: viewModel, isPresented: $showAddTask)
        }
        .onAppear {
            appState.selectedTaskID = nil
            appState.selectedColumnIndex = nil
            isQuickAddFocused = true
        }
        .focusable(interactions: .activate)
        .focused($isBoardFocused)
        .onKeyPress(.escape) {
            appState.selectedTaskID = nil
            appState.selectedColumnIndex = nil
            return .handled
        }
        .onKeyPress(.return) {
            if appState.selectedTaskID != nil {
                showTaskDetail = true
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.delete) {
            if selectedTask != nil {
                deleteSelectedTask()
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.upArrow) {
            moveSelection(direction: .up)
            return .handled
        }
        .onKeyPress(.downArrow) {
            moveSelection(direction: .down)
            return .handled
        }
        .onKeyPress(.leftArrow) {
            moveSelection(direction: .left)
            return .handled
        }
        .onKeyPress(.rightArrow) {
            moveSelection(direction: .right)
            return .handled
        }
        .sheet(isPresented: $showTaskDetail, onDismiss: { isBoardFocused = true }) {
            if let task = selectedTask {
                TaskDetailView(task: task, viewModel: viewModel)
            }
        }
        .onChange(of: appState.triggerQuickAdd) { _, newValue in
            if newValue {
                isQuickAddFocused = true
                appState.triggerQuickAdd = false
            }
        }
        .onChange(of: showAddColumn) { _, isShowing in
            if !isShowing { isBoardFocused = true }
        }
        .onChange(of: showAddTask) { _, isShowing in
            if !isShowing { isBoardFocused = true }
        }
    }

    private func quickAddTask() {
        let trimmed = quickTaskTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let firstColumn = viewModel.sortedColumns.first else { return }
        viewModel.addTask(title: trimmed, to: firstColumn)
        quickTaskTitle = ""
    }

    private var selectedTask: TaskItem? {
        guard let id = appState.selectedTaskID else { return nil }
        for column in viewModel.sortedColumns {
            if let task = column.tasks.first(where: { $0.id == id }) {
                return task
            }
        }
        return nil
    }

    private func deleteSelectedTask() {
        guard let task = selectedTask else { return }
        appState.selectedTaskID = nil
        withAnimation(.easeInOut(duration: 0.25)) {
            viewModel.deleteTask(task)
        }
    }

    private enum Direction { case up, down, left, right }

    private func moveSelection(direction: Direction) {
        let columns = viewModel.sortedColumns
        guard !columns.isEmpty else { return }

        var currentColIdx = appState.selectedColumnIndex ?? 0
        let currentTaskID = appState.selectedTaskID

        switch direction {
        case .left:
            currentColIdx = max(0, currentColIdx - 1)
            appState.selectedColumnIndex = currentColIdx
            let tasks = viewModel.sortedTasks(for: columns[currentColIdx])
            appState.selectedTaskID = tasks.first?.id
        case .right:
            currentColIdx = min(columns.count - 1, currentColIdx + 1)
            appState.selectedColumnIndex = currentColIdx
            let tasks = viewModel.sortedTasks(for: columns[currentColIdx])
            appState.selectedTaskID = tasks.first?.id
        case .up, .down:
            let colIdx = min(currentColIdx, columns.count - 1)
            appState.selectedColumnIndex = colIdx
            let tasks = viewModel.sortedTasks(for: columns[colIdx])
            guard !tasks.isEmpty else { return }
            if let taskID = currentTaskID, let idx = tasks.firstIndex(where: { $0.id == taskID }) {
                let newIdx = direction == .up ? max(0, idx - 1) : min(tasks.count - 1, idx + 1)
                appState.selectedTaskID = tasks[newIdx].id
            } else {
                appState.selectedTaskID = tasks.first?.id
            }
        }
    }
}
