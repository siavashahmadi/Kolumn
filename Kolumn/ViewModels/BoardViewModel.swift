import SwiftData
import SwiftUI

@MainActor @Observable final class BoardViewModel {
    let modelContext: ModelContext
    var board: Board

    var sortedColumns: [Column] {
        board.columns.sorted { $0.sortOrder < $1.sortOrder }
    }

    init(board: Board, modelContext: ModelContext) {
        self.board = board
        self.modelContext = modelContext
    }

    func addColumn(title: String) {
        let maxOrder = board.columns.map(\.sortOrder).max() ?? -1
        let column = Column(title: title, sortOrder: maxOrder + 1)
        column.board = board
        board.columns.append(column)
        save()
    }

    func deleteColumn(_ column: Column) {
        board.columns.removeAll { $0.id == column.id }
        modelContext.delete(column)
        save()
    }

    func renameColumn(_ column: Column, to newTitle: String) {
        column.title = newTitle
        save()
    }

    func reorderColumns(from source: IndexSet, to destination: Int) {
        var cols = sortedColumns
        cols.move(fromOffsets: source, toOffset: destination)
        for (index, col) in cols.enumerated() {
            col.sortOrder = index
        }
        save()
    }

    func addTask(title: String, to column: Column) {
        let maxOrder = column.tasks.map(\.sortOrder).max() ?? -1
        let task = TaskItem(title: title)
        task.sortOrder = maxOrder + 1
        task.column = column
        column.tasks.append(task)
        save()
    }

    func deleteTask(_ task: TaskItem) {
        if let column = task.column {
            column.tasks.removeAll { $0.id == task.id }
        }
        modelContext.delete(task)
        save()
    }

    func moveTask(withID taskID: String, to targetColumn: Column) {
        guard let uuid = UUID(uuidString: taskID) else { return }

        for column in board.columns {
            if let task = column.tasks.first(where: { $0.id == uuid }) {
                column.tasks.removeAll { $0.id == uuid }
                let maxOrder = targetColumn.tasks.map(\.sortOrder).max() ?? -1
                task.sortOrder = maxOrder + 1
                task.column = targetColumn
                targetColumn.tasks.append(task)
                save()
                return
            }
        }
    }

    func sortedTasks(for column: Column) -> [TaskItem] {
        column.tasks.sorted { $0.sortOrder < $1.sortOrder }
    }

    private func save() {
        do {
            try modelContext.save()
        } catch {
            print("Save failed: \(error.localizedDescription)")
        }
    }
}
