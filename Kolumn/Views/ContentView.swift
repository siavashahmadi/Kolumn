import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Environment(\.appTheme) private var theme
    @Query(sort: \Board.sortOrder) private var boards: [Board]
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    private var selectedBoard: Board? {
        guard let id = appState.selectedBoardID else { return nil }
        return boards.first { $0.persistentModelID == id }
    }

    var body: some View {
        @Bindable var appState = appState

        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 230, max: 280)
        } detail: {
            if let board = selectedBoard {
                BoardView(board: board, modelContext: modelContext)
                    .id(board.id)
            } else {
                EmptyBoardView()
            }
        }
        .navigationSplitViewStyle(.balanced)
        .background(theme.backgroundColor)
    }
}
