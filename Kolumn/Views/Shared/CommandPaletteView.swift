import SwiftUI
import SwiftData

struct CommandPaletteView: View {
    @Environment(\.appTheme) private var theme
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var results: [TaskItem] = []
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(theme.secondaryTextColor)
                TextField("Search tasks...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .focused($isSearchFocused)
                    .onChange(of: searchText) { _, newValue in
                        performSearch(newValue)
                    }
                Button {
                    appState.isCommandPaletteOpen = false
                } label: {
                    Text("ESC")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(theme.secondaryTextColor.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
            }
            .padding(12)

            if !results.isEmpty {
                Divider()
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(results) { task in
                            Button {
                                navigateToTask(task)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(task.title)
                                            .font(.body)
                                            .foregroundStyle(theme.primaryTextColor)
                                        if let column = task.column, let board = column.board {
                                            Text("\(board.emoji) \(board.name) > \(column.title)")
                                                .font(.caption)
                                                .foregroundStyle(theme.secondaryTextColor)
                                        }
                                    }
                                    Spacer()
                                    PriorityBadgeView(priority: task.priority)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxHeight: 300)
            } else if !searchText.isEmpty {
                Divider()
                Text("No tasks found")
                    .font(.callout)
                    .foregroundStyle(theme.secondaryTextColor)
                    .padding(16)
            }
        }
        .background(theme.cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
        .frame(width: 480)
        .onAppear {
            isSearchFocused = true
        }
        .onExitCommand {
            appState.isCommandPaletteOpen = false
        }
    }

    private func performSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            results = []
            return
        }

        var descriptor = FetchDescriptor<TaskItem>()
        descriptor.predicate = #Predicate<TaskItem> { task in
            task.title.localizedStandardContains(trimmed) ||
            task.notes.localizedStandardContains(trimmed)
        }
        descriptor.fetchLimit = 20

        results = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func navigateToTask(_ task: TaskItem) {
        if let column = task.column, let board = column.board {
            appState.selectedBoardID = board.persistentModelID
            appState.selectedTaskID = task.id
        }
        appState.isCommandPaletteOpen = false
    }
}
