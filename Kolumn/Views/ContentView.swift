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
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 230, max: 280)
        } detail: {
            if let board = selectedBoard {
                BoardView(board: board, modelContext: modelContext)
                    .id(board.id)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "rectangle.on.rectangle.angled")
                        .font(.system(size: 48))
                        .foregroundStyle(theme.accentColor.opacity(0.6))
                    Text("No Board Selected")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundStyle(theme.primaryTextColor)
                    Text("Create a new board or select one from the sidebar to get started.")
                        .font(.body)
                        .foregroundStyle(theme.secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 300)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(theme.backgroundColor)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .background(theme.backgroundColor)
        .animation(.easeInOut(duration: 0.3), value: theme.id)
        .overlay {
            if appState.isCommandPaletteOpen {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        appState.isCommandPaletteOpen = false
                    }
                VStack {
                    CommandPaletteView()
                        .padding(.top, 80)
                    Spacer()
                }
            }
        }
    }
}
