import SwiftUI
import SwiftData

struct BoardView: View {
    let board: Board
    @Environment(\.appTheme) private var theme
    @Environment(ThemeManager.self) private var themeManager
    @State private var viewModel: BoardViewModel
    @State private var showAddColumn = false
    @State private var showAddTask = false
    @State private var quickTaskTitle = ""
    @FocusState private var isQuickAddFocused: Bool

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
                    ForEach(viewModel.sortedColumns) { column in
                        ColumnView(column: column, viewModel: viewModel)
                            .frame(width: needsScroll ? 260 : columnWidth)
                    }
                }
                .padding(20)
                .frame(maxHeight: .infinity, alignment: .top)
            }
        }
        .background(theme.backgroundColor)
        .navigationTitle("\(board.emoji) \(board.name)")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Menu {
                    ForEach(AppTheme.all) { t in
                        Button {
                            themeManager.current = t
                        } label: {
                            if t.id == themeManager.current.id {
                                Label(t.name, systemImage: "checkmark")
                            } else {
                                Text(t.name)
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
        }
        .sheet(isPresented: $showAddColumn) {
            AddColumnView(viewModel: viewModel)
        }
        .sheet(isPresented: $showAddTask) {
            AddTaskPopoverView(viewModel: viewModel, isPresented: $showAddTask)
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
}
