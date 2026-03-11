import Foundation
import SwiftData
import XCTest
@testable import Kolumn

@MainActor
func makeTestContainer() throws -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(
        for: Board.self, Column.self, TaskItem.self, Tag.self, Subtask.self,
        configurations: config
    )
}

@MainActor
func makeTestBoard(in container: ModelContainer) -> (Board, BoardViewModel) {
    let context = container.mainContext
    let board = Board(name: "Test Board", emoji: "🧪")
    board.sortOrder = 0
    context.insert(board)

    let cols = ["To Do", "In Progress", "Done"]
    for (i, title) in cols.enumerated() {
        let col = Column(title: title, sortOrder: i)
        col.board = board
        board.columns.append(col)
    }

    try? context.save()
    let vm = BoardViewModel(board: board, modelContext: context)
    return (board, vm)
}

@MainActor
func makePopulatedBoard(
    in container: ModelContainer,
    columnCount: Int,
    tasksPerColumn: Int
) -> (Board, BoardViewModel) {
    let context = container.mainContext
    let board = Board(name: "Populated Board", emoji: "📊")
    context.insert(board)

    for colIdx in 0..<columnCount {
        let col = Column(title: "Column \(colIdx)", sortOrder: colIdx)
        col.board = board
        board.columns.append(col)

        for taskIdx in 0..<tasksPerColumn {
            let task = TaskItem(title: "Col\(colIdx)-Task\(taskIdx)")
            task.sortOrder = taskIdx
            task.column = col
            col.tasks.append(task)
        }
    }

    try? context.save()
    let vm = BoardViewModel(board: board, modelContext: context)
    return (board, vm)
}

@MainActor
func makeLargeBoard(in container: ModelContainer, taskCount: Int) -> (Board, BoardViewModel) {
    let context = container.mainContext
    let board = Board(name: "Large Board", emoji: "🏗️")
    context.insert(board)

    let columnCount = 5
    var columns: [Column] = []
    for i in 0..<columnCount {
        let col = Column(title: "Col \(i)", sortOrder: i)
        col.board = board
        board.columns.append(col)
        columns.append(col)
    }

    let priorities: [Priority] = [.low, .medium, .high]
    for i in 0..<taskCount {
        let col = columns[i % columnCount]
        let task = TaskItem(title: "Task \(i)", priority: priorities[i % 3])
        task.sortOrder = col.tasks.count
        task.column = col

        // Every 3rd task gets a due date
        if i % 3 == 0 {
            task.dueDate = Date.now.addingTimeInterval(Double(i) * 3600)
        }

        // Every 5th task gets subtasks
        if i % 5 == 0 {
            for s in 0..<3 {
                let subtask = Subtask(title: "Sub \(s)", sortOrder: s)
                subtask.taskItem = task
                task.subtasks.append(subtask)
            }
        }

        col.tasks.append(task)
    }

    try? context.save()
    let vm = BoardViewModel(board: board, modelContext: context)
    return (board, vm)
}

@MainActor
func makeTaskWithSubtasks(
    in viewModel: BoardViewModel,
    column: Column,
    subtaskCount: Int
) -> TaskItem {
    viewModel.addTask(title: "Parent Task", to: column)
    let task = viewModel.sortedTasks(for: column).last!

    for i in 0..<subtaskCount {
        viewModel.addSubtask(title: "Subtask \(i)", to: task)
    }
    return task
}

func cleanUserDefaults() {
    UserDefaults.standard.removeObject(forKey: "appearanceMode")
    UserDefaults.standard.removeObject(forKey: "selectedLightThemeID")
    UserDefaults.standard.removeObject(forKey: "selectedDarkThemeID")
}

func assertSortOrderConsecutive<T: HasSortOrder>(
    _ items: [T],
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let sortOrders = items.map(\.sortOrder).sorted()
    let expected = Array(0..<items.count)
    XCTAssertEqual(sortOrders, expected, "SortOrders should be consecutive 0..\(items.count - 1), got \(sortOrders)", file: file, line: line)
}

protocol HasSortOrder {
    var sortOrder: Int { get }
}

extension Column: HasSortOrder {}
extension TaskItem: HasSortOrder {}
extension Subtask: HasSortOrder {}
