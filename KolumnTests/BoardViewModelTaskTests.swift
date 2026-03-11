import XCTest
import SwiftData
@testable import Kolumn

@MainActor
final class BoardViewModelTaskTests: XCTestCase {

    private var container: ModelContainer!
    private var board: Board!
    private var viewModel: BoardViewModel!

    override func setUp() async throws {
        try await super.setUp()
        container = try makeTestContainer()
        let result = makeTestBoard(in: container)
        board = result.0
        viewModel = result.1
    }

    // MARK: - Add Task

    func testAddTaskSortOrderIncrements() {
        let col = viewModel.sortedColumns.first!
        viewModel.addTask(title: "A", to: col)
        viewModel.addTask(title: "B", to: col)
        viewModel.addTask(title: "C", to: col)

        let tasks = viewModel.sortedTasks(for: col)
        XCTAssertEqual(tasks.map(\.sortOrder), [0, 1, 2])
    }

    func testAddTaskSetsColumnReference() {
        let col = viewModel.sortedColumns.first!
        viewModel.addTask(title: "Task", to: col)
        let task = viewModel.sortedTasks(for: col).first!
        XCTAssertEqual(task.column?.id, col.id)
    }

    func testAddTaskToEmptyColumn() {
        let col = viewModel.sortedColumns.first!
        XCTAssertEqual(viewModel.sortedTasks(for: col).count, 0)

        viewModel.addTask(title: "First", to: col)
        let task = viewModel.sortedTasks(for: col).first!
        XCTAssertEqual(task.sortOrder, 0)
    }

    // MARK: - Delete Task

    func testDeleteTaskFromMiddle() {
        let col = viewModel.sortedColumns.first!
        viewModel.addTask(title: "A", to: col)
        viewModel.addTask(title: "B", to: col)
        viewModel.addTask(title: "C", to: col)

        let middle = viewModel.sortedTasks(for: col)[1]
        viewModel.deleteTask(middle)

        let remaining = viewModel.sortedTasks(for: col)
        XCTAssertEqual(remaining.count, 2)
        XCTAssertEqual(remaining.map(\.title), ["A", "C"])
    }

    func testDeleteTaskUpdatesColumnTasks() {
        let col = viewModel.sortedColumns.first!
        viewModel.addTask(title: "Task", to: col)
        let task = viewModel.sortedTasks(for: col).first!
        let taskID = task.id

        viewModel.deleteTask(task)
        XCTAssertFalse(col.tasks.contains(where: { $0.id == taskID }))
    }

    func testDeleteOrphanedTask() {
        // Task with nil column
        let task = TaskItem(title: "Orphan")
        container.mainContext.insert(task)
        try? container.mainContext.save()

        // Should not crash
        viewModel.deleteTask(task)
    }

    // MARK: - Move Task

    func testMoveTaskSetsNewColumn() {
        let col1 = viewModel.sortedColumns[0]
        let col2 = viewModel.sortedColumns[1]
        viewModel.addTask(title: "Moving", to: col1)
        let task = viewModel.sortedTasks(for: col1).first!

        viewModel.moveTask(withID: task.id.uuidString, to: col2)
        XCTAssertEqual(task.column?.id, col2.id)
    }

    func testMoveTaskRemovesFromSource() {
        let col1 = viewModel.sortedColumns[0]
        let col2 = viewModel.sortedColumns[1]
        viewModel.addTask(title: "Moving", to: col1)
        let task = viewModel.sortedTasks(for: col1).first!

        viewModel.moveTask(withID: task.id.uuidString, to: col2)
        XCTAssertEqual(viewModel.sortedTasks(for: col1).count, 0)
    }

    func testMoveTaskAddsToTarget() {
        let col1 = viewModel.sortedColumns[0]
        let col2 = viewModel.sortedColumns[1]
        viewModel.addTask(title: "Moving", to: col1)
        let task = viewModel.sortedTasks(for: col1).first!

        viewModel.moveTask(withID: task.id.uuidString, to: col2)
        XCTAssertEqual(viewModel.sortedTasks(for: col2).count, 1)
        XCTAssertEqual(viewModel.sortedTasks(for: col2).first?.title, "Moving")
    }

    func testMoveTaskToSameColumn() {
        let col = viewModel.sortedColumns.first!
        viewModel.addTask(title: "Stay", to: col)
        let task = viewModel.sortedTasks(for: col).first!

        viewModel.moveTask(withID: task.id.uuidString, to: col)

        // Should still be in column, no duplication
        XCTAssertEqual(viewModel.sortedTasks(for: col).count, 1)
        XCTAssertEqual(viewModel.sortedTasks(for: col).first?.title, "Stay")
    }

    func testMoveTaskInvalidUUIDString() {
        let col = viewModel.sortedColumns.first!
        viewModel.addTask(title: "Task", to: col)

        // Should not crash
        viewModel.moveTask(withID: "not-a-uuid", to: col)
        XCTAssertEqual(viewModel.sortedTasks(for: col).count, 1)
    }

    func testMoveTaskValidUUIDNoMatch() {
        let col = viewModel.sortedColumns.first!
        viewModel.addTask(title: "Task", to: col)

        let fakeUUID = UUID().uuidString
        viewModel.moveTask(withID: fakeUUID, to: col)
        XCTAssertEqual(viewModel.sortedTasks(for: col).count, 1)
    }

    // MARK: - Move Task With Position

    func testMoveTaskWithPositionToBeginning() {
        let col = viewModel.sortedColumns.first!
        viewModel.addTask(title: "A", to: col)
        viewModel.addTask(title: "B", to: col)
        viewModel.addTask(title: "C", to: col)

        let last = viewModel.sortedTasks(for: col).last!
        viewModel.moveTask(withID: last.id.uuidString, to: col, at: 0)

        let tasks = viewModel.sortedTasks(for: col)
        XCTAssertEqual(tasks.map(\.title), ["C", "A", "B"])
        assertSortOrderConsecutive(tasks)
    }

    func testMoveTaskWithPositionToEnd() {
        let col = viewModel.sortedColumns.first!
        viewModel.addTask(title: "A", to: col)
        viewModel.addTask(title: "B", to: col)
        viewModel.addTask(title: "C", to: col)

        let first = viewModel.sortedTasks(for: col).first!
        viewModel.moveTask(withID: first.id.uuidString, to: col, at: 3)

        let tasks = viewModel.sortedTasks(for: col)
        XCTAssertEqual(tasks.map(\.title), ["B", "C", "A"])
        assertSortOrderConsecutive(tasks)
    }

    func testMoveTaskWithPositionToMiddle() {
        let col = viewModel.sortedColumns.first!
        viewModel.addTask(title: "A", to: col)
        viewModel.addTask(title: "B", to: col)
        viewModel.addTask(title: "C", to: col)

        let first = viewModel.sortedTasks(for: col).first!
        viewModel.moveTask(withID: first.id.uuidString, to: col, at: 1)

        let tasks = viewModel.sortedTasks(for: col)
        XCTAssertEqual(tasks.map(\.title), ["B", "A", "C"])
    }

    func testMoveTaskWithPositionOutOfBounds() {
        let col = viewModel.sortedColumns.first!
        viewModel.addTask(title: "A", to: col)
        viewModel.addTask(title: "B", to: col)

        let first = viewModel.sortedTasks(for: col).first!
        // Position 999 should clamp to end
        viewModel.moveTask(withID: first.id.uuidString, to: col, at: 999)

        let tasks = viewModel.sortedTasks(for: col)
        XCTAssertEqual(tasks.last?.title, "A")
    }

    func testMoveTaskBetweenColumnsWithPosition() {
        let col1 = viewModel.sortedColumns[0]
        let col2 = viewModel.sortedColumns[1]

        // Populate col2 with 3 tasks
        viewModel.addTask(title: "X", to: col2)
        viewModel.addTask(title: "Y", to: col2)
        viewModel.addTask(title: "Z", to: col2)

        // Add task to col1 and move it to col2 at position 1
        viewModel.addTask(title: "Inserted", to: col1)
        let task = viewModel.sortedTasks(for: col1).first!
        viewModel.moveTask(withID: task.id.uuidString, to: col2, at: 1)

        let col2Tasks = viewModel.sortedTasks(for: col2)
        XCTAssertEqual(col2Tasks.count, 4)
        XCTAssertEqual(col2Tasks[1].title, "Inserted")
        XCTAssertEqual(viewModel.sortedTasks(for: col1).count, 0)
    }

    // MARK: - Archive

    func testArchiveTaskSetsFlag() {
        let col = viewModel.sortedColumns.first!
        viewModel.addTask(title: "Task", to: col)
        let task = viewModel.sortedTasks(for: col).first!

        XCTAssertFalse(task.isArchived)
        viewModel.archiveTask(task)
        XCTAssertTrue(task.isArchived)
    }

    func testUnarchiveTaskClearsFlag() {
        let col = viewModel.sortedColumns.first!
        viewModel.addTask(title: "Task", to: col)
        let task = viewModel.sortedTasks(for: col).first!

        viewModel.archiveTask(task)
        XCTAssertTrue(task.isArchived)
        viewModel.unarchiveTask(task)
        XCTAssertFalse(task.isArchived)
    }

    func testSortedTasksDefaultHidesArchived() {
        let col = viewModel.sortedColumns.first!
        viewModel.addTask(title: "Active", to: col)
        viewModel.addTask(title: "Archived", to: col)

        let archivedTask = viewModel.sortedTasks(for: col).last!
        viewModel.archiveTask(archivedTask)

        let visible = viewModel.sortedTasks(for: col)
        XCTAssertEqual(visible.count, 1)
        XCTAssertEqual(visible.first?.title, "Active")
    }

    func testSortedTasksShowArchivedIncludesAll() {
        let col = viewModel.sortedColumns.first!
        viewModel.addTask(title: "Active", to: col)
        viewModel.addTask(title: "Archived", to: col)

        let archivedTask = viewModel.sortedTasks(for: col).last!
        viewModel.archiveTask(archivedTask)

        let all = viewModel.sortedTasks(for: col, showArchived: true)
        XCTAssertEqual(all.count, 2)
    }

    func testTaskSortOrderAfterMultipleAdds() {
        let col = viewModel.sortedColumns.first!
        for i in 0..<5 {
            viewModel.addTask(title: "Task \(i)", to: col)
        }

        let tasks = viewModel.sortedTasks(for: col)
        XCTAssertEqual(tasks.count, 5)
        for (i, task) in tasks.enumerated() {
            XCTAssertEqual(task.sortOrder, i)
        }
    }
}
