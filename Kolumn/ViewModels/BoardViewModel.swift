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

    func addColumn(title: String, colorHex: String = "#C3B1E1") {
        let maxOrder = board.columns.map(\.sortOrder).max() ?? -1
        let column = Column(title: title, sortOrder: maxOrder + 1, colorHex: colorHex)
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

    func changeColumnColor(_ column: Column, to colorHex: String) {
        column.colorHex = colorHex
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

    func moveTask(withID taskID: String, to targetColumn: Column, at insertionIndex: Int) {
        guard let uuid = UUID(uuidString: taskID) else { return }

        for column in board.columns {
            if let task = column.tasks.first(where: { $0.id == uuid }) {
                column.tasks.removeAll { $0.id == uuid }
                task.column = targetColumn
                if !targetColumn.tasks.contains(where: { $0.id == uuid }) {
                    targetColumn.tasks.append(task)
                }
                // Recompute sortOrders for all tasks in target column
                var sorted = targetColumn.tasks.filter { $0.id != uuid }.sorted { $0.sortOrder < $1.sortOrder }
                let clampedIndex = min(insertionIndex, sorted.count)
                sorted.insert(task, at: clampedIndex)
                for (i, t) in sorted.enumerated() {
                    t.sortOrder = i
                }
                save()
                return
            }
        }
    }

    func sortedTasks(for column: Column) -> [TaskItem] {
        column.tasks
            .filter { !$0.isArchived }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    // MARK: - Subtasks

    func addSubtask(title: String, to task: TaskItem) {
        let maxOrder = task.subtasks.map(\.sortOrder).max() ?? -1
        let subtask = Subtask(title: title, sortOrder: maxOrder + 1)
        subtask.taskItem = task
        task.subtasks.append(subtask)
        save()
    }

    func deleteSubtask(_ subtask: Subtask, from task: TaskItem) {
        task.subtasks.removeAll { $0.id == subtask.id }
        modelContext.delete(subtask)
        save()
    }

    func toggleSubtask(_ subtask: Subtask) {
        subtask.isCompleted.toggle()
        save()
    }

    func reorderSubtasks(of task: TaskItem, from source: IndexSet, to destination: Int) {
        var sorted = task.subtasks.sorted { $0.sortOrder < $1.sortOrder }
        sorted.move(fromOffsets: source, toOffset: destination)
        for (i, s) in sorted.enumerated() {
            s.sortOrder = i
        }
        save()
    }

    private func save() {
        do {
            try modelContext.save()
        } catch {
            print("Save failed: \(error.localizedDescription)")
        }
    }
}
