import SwiftUI
import SwiftData

struct SidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Environment(\.appTheme) private var theme
    @Query(sort: \Board.sortOrder) private var boards: [Board]
    @State private var showNewBoard = false
    @State private var newBoardName = ""
    @State private var newBoardEmoji = "📋"
    @State private var boardToRename: Board?
    @State private var renameBoardText = ""
    @State private var isHoveringNewBoard = false

    var body: some View {
        @Bindable var appState = appState

        List(selection: Binding(
            get: { appState.selectedBoardID },
            set: { appState.selectedBoardID = $0 }
        )) {
            Section("Boards") {
                ForEach(boards) { board in
                    SidebarRowView(board: board)
                        .tag(board.persistentModelID)
                        .contextMenu {
                            Button("Rename Board") {
                                renameBoardText = board.name
                                boardToRename = board
                            }
                            Divider()
                            Button("Delete Board", role: .destructive) {
                                deleteBoard(board)
                            }
                        }
                }
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Divider()
                Button {
                    showNewBoard = true
                } label: {
                    Label("New Board", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isHoveringNewBoard ? theme.accentColor.opacity(0.12) : .clear)
                        )
                }
                .buttonStyle(.plain)
                .foregroundStyle(isHoveringNewBoard ? theme.accentColor : theme.primaryTextColor)
                .fontWeight(.medium)
                .onHover { isHoveringNewBoard = $0 }
                .animation(.easeInOut(duration: 0.15), value: isHoveringNewBoard)
            }
        }
        .sheet(isPresented: $showNewBoard) {
            newBoardSheet
        }
        .onChange(of: appState.showNewBoardSheet) { _, newValue in
            if newValue {
                showNewBoard = true
                appState.showNewBoardSheet = false
            }
        }
        .alert("Rename Board", isPresented: Binding(
            get: { boardToRename != nil },
            set: { if !$0 { boardToRename = nil } }
        )) {
            TextField("Board name", text: $renameBoardText)
            Button("Cancel", role: .cancel) { boardToRename = nil }
            Button("Rename") {
                if let board = boardToRename {
                    let trimmed = renameBoardText.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty {
                        board.name = trimmed
                        try? modelContext.save()
                    }
                }
                boardToRename = nil
            }
        }
        .onAppear {
            if appState.selectedBoardID == nil, let first = boards.first {
                appState.selectedBoardID = first.persistentModelID
            }
        }
    }

    private var newBoardSheet: some View {
        VStack(spacing: 16) {
            Text("New Board")
                .font(.headline)

            HStack {
                TextField("Emoji", text: $newBoardEmoji)
                    .frame(width: 44)
                    .multilineTextAlignment(.center)
                TextField("Board name", text: $newBoardName)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Button("Cancel") {
                    showNewBoard = false
                    newBoardName = ""
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Create") {
                    createBoard()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(newBoardName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 320)
    }

    private func createBoard() {
        let board = Board(name: newBoardName.trimmingCharacters(in: .whitespaces), emoji: newBoardEmoji)
        board.sortOrder = boards.count
        let defaults = Column.defaultColumns()
        for col in defaults {
            col.board = board
        }
        board.columns = defaults
        modelContext.insert(board)
        try? modelContext.save()
        appState.selectedBoardID = board.persistentModelID
        newBoardName = ""
        newBoardEmoji = "📋"
        showNewBoard = false
    }

    private func deleteBoard(_ board: Board) {
        if appState.selectedBoardID == board.persistentModelID {
            appState.selectedBoardID = nil
        }
        withAnimation(.easeInOut(duration: 0.25)) {
            modelContext.delete(board)
            try? modelContext.save()
        }
        if appState.selectedBoardID == nil, let first = boards.first(where: { $0.persistentModelID != board.persistentModelID }) {
            appState.selectedBoardID = first.persistentModelID
        }
    }
}
