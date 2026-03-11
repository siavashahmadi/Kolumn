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
    @FocusState private var isQuickAddFocused: Bool
    @FocusState private var isBoardFocused: Bool
    @Environment(\.undoManager) private var undoManager

    init(board: Board, modelContext: ModelContext) {
        self.board = board
        _viewModel = State(initialValue: BoardViewModel(board: board, modelContext: modelContext))
    }

    var body: some View {
        GeometryReader { geo in
            let columnCount = viewModel.sortedColumns.count
            let totalSpacing = CGFloat(max(columnCount - 1, 0)) * 12
            let padding: CGFloat = 20 * 2
            let availableWidth = geo.size.width - padding - totalSpacing
            let columnWidth = columnCount > 0
                ? max(220, min(320, availableWidth / CGFloat(columnCount)))
                : 280
            let needsScroll = columnWidth <= 220 && columnCount > 0

            ScrollView(needsScroll ? .horizontal : []) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(Array(viewModel.sortedColumns.enumerated()), id: \.element.id) { index, column in
                        ColumnView(column: column, columnIndex: index, viewModel: viewModel)
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
            ToolbarItem(placement: .automatic) {
                Menu {
                    Section("Light") {
                        ForEach(AppTheme.lightThemes) { t in
                            Button {
                                themeManager.selectedLightThemeID = t.id
                                themeManager.appearanceMode = .light
                            } label: {
                                if t.id == themeManager.selectedLightThemeID {
                                    Label(t.name, systemImage: "checkmark")
                                } else {
                                    Text(t.name)
                                }
                            }
                        }
                    }
                    Section("Dark") {
                        ForEach(AppTheme.darkThemes) { t in
                            Button {
                                themeManager.selectedDarkThemeID = t.id
                                themeManager.appearanceMode = .dark
                            } label: {
                                if t.id == themeManager.selectedDarkThemeID {
                                    Label(t.name, systemImage: "checkmark")
                                } else {
                                    Text(t.name)
                                }
                            }
                        }
                    }
                } label: {
                    Label("Theme", systemImage: "paintpalette")
                }
            }

            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    TextField("Add task", text: $quickTaskTitle)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 200)
                        .focused($isQuickAddFocused)
                        .onSubmit { quickAddTask() }

                    Button {
                        if quickTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                            showAddTask = true
                        } else {
                            quickAddTask()
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(theme.accentColor)
                    }
                    .buttonStyle(.plain)
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button("Add Column", systemImage: "plus.rectangle.on.rectangle") {
                    showAddColumn = true
                }
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    appState.showArchivedTasks.toggle()
                } label: {
                    Label(
                        appState.showArchivedTasks ? "Hide Archived" : "Show Archived",
                        systemImage: appState.showArchivedTasks ? "archivebox.fill" : "archivebox"
                    )
                }
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    showStats.toggle()
                } label: {
                    Label("Stats", systemImage: "chart.bar")
                }
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
            viewModel.modelContext.undoManager = undoManager
        }
        .focusable()
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
            deleteSelectedTask()
            return .handled
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
        .sheet(isPresented: $showTaskDetail) {
            if let task = selectedTask {
                TaskDetailView(task: task, viewModel: viewModel)
            }
        }
        .background {
            Button("") { isQuickAddFocused = true }
                .keyboardShortcut("n", modifiers: .command)
                .opacity(0)
                .frame(width: 0, height: 0)
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

        // Find current position
        var currentColIdx = appState.selectedColumnIndex ?? 0
        let currentTaskID = appState.selectedTaskID

        switch direction {
        case .left:
            currentColIdx = max(0, currentColIdx - 1)
            appState.selectedColumnIndex = currentColIdx
            let tasks = viewModel.sortedTasks(for: columns[currentColIdx], showArchived: appState.showArchivedTasks)
            appState.selectedTaskID = tasks.first?.id
        case .right:
            currentColIdx = min(columns.count - 1, currentColIdx + 1)
            appState.selectedColumnIndex = currentColIdx
            let tasks = viewModel.sortedTasks(for: columns[currentColIdx], showArchived: appState.showArchivedTasks)
            appState.selectedTaskID = tasks.first?.id
        case .up, .down:
            let colIdx = min(currentColIdx, columns.count - 1)
            appState.selectedColumnIndex = colIdx
            let tasks = viewModel.sortedTasks(for: columns[colIdx], showArchived: appState.showArchivedTasks)
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
