import XCTest
import SwiftData
@testable import Kolumn

@MainActor
final class BoardViewModelSubtaskTests: XCTestCase {

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

    private func makeParentTask() -> (Column, TaskItem) {
        let col = viewModel.sortedColumns.first!
        viewModel.addTask(title: "Parent", to: col)
        let task = viewModel.sortedTasks(for: col).first!
        return (col, task)
    }

    func testAddSubtaskSortOrderIncrements() {
        let (_, task) = makeParentTask()
        viewModel.addSubtask(title: "A", to: task)
        viewModel.addSubtask(title: "B", to: task)
        viewModel.addSubtask(title: "C", to: task)

        let sorted = task.subtasks.sorted { $0.sortOrder < $1.sortOrder }
        XCTAssertEqual(sorted.map(\.sortOrder), [0, 1, 2])
    }

    func testAddSubtaskSetsTaskItemReference() {
        let (_, task) = makeParentTask()
        viewModel.addSubtask(title: "Sub", to: task)
        let subtask = task.subtasks.first!
        XCTAssertEqual(subtask.taskItem?.id, task.id)
    }

    func testAddSubtaskToTaskWithNoSubtasks() {
        let (_, task) = makeParentTask()
        XCTAssertTrue(task.subtasks.isEmpty)

        viewModel.addSubtask(title: "First", to: task)
        XCTAssertEqual(task.subtasks.first?.sortOrder, 0)
    }

    func testDeleteSubtaskRemovesFromTask() {
        let (_, task) = makeParentTask()
        viewModel.addSubtask(title: "Sub", to: task)
        let subtask = task.subtasks.first!
        let subtaskID = subtask.id

        viewModel.deleteSubtask(subtask, from: task)
        XCTAssertFalse(task.subtasks.contains(where: { $0.id == subtaskID }))
    }

    func testDeleteSubtaskFromMiddle() {
        let (_, task) = makeParentTask()
        viewModel.addSubtask(title: "A", to: task)
        viewModel.addSubtask(title: "B", to: task)
        viewModel.addSubtask(title: "C", to: task)

        let sorted = task.subtasks.sorted { $0.sortOrder < $1.sortOrder }
        let middle = sorted[1]
        viewModel.deleteSubtask(middle, from: task)

        XCTAssertEqual(task.subtasks.count, 2)
        let titles = task.subtasks.sorted { $0.sortOrder < $1.sortOrder }.map(\.title)
        XCTAssertEqual(titles, ["A", "C"])
    }

    func testDeleteAllSubtasks() {
        let (_, task) = makeParentTask()
        viewModel.addSubtask(title: "A", to: task)
        viewModel.addSubtask(title: "B", to: task)
        viewModel.addSubtask(title: "C", to: task)

        for sub in task.subtasks {
            viewModel.deleteSubtask(sub, from: task)
        }
        XCTAssertTrue(task.subtasks.isEmpty)
    }

    func testToggleSubtaskCompletedToIncomplete() {
        let (_, task) = makeParentTask()
        viewModel.addSubtask(title: "Toggle", to: task)
        let subtask = task.subtasks.first!

        subtask.isCompleted = true
        viewModel.toggleSubtask(subtask)
        XCTAssertFalse(subtask.isCompleted)
    }

    func testToggleSubtaskTwiceReturns() {
        let (_, task) = makeParentTask()
        viewModel.addSubtask(title: "Toggle", to: task)
        let subtask = task.subtasks.first!

        let original = subtask.isCompleted
        viewModel.toggleSubtask(subtask)
        viewModel.toggleSubtask(subtask)
        XCTAssertEqual(subtask.isCompleted, original)
    }

    func testReorderSubtasksFirstToLast() {
        let (_, task) = makeParentTask()
        viewModel.addSubtask(title: "A", to: task)
        viewModel.addSubtask(title: "B", to: task)
        viewModel.addSubtask(title: "C", to: task)

        viewModel.reorderSubtasks(of: task, from: IndexSet(integer: 0), to: 3)

        let sorted = task.subtasks.sorted { $0.sortOrder < $1.sortOrder }
        XCTAssertEqual(sorted.map(\.title), ["B", "C", "A"])
    }

    func testReorderSubtasksLastToFirst() {
        let (_, task) = makeParentTask()
        viewModel.addSubtask(title: "A", to: task)
        viewModel.addSubtask(title: "B", to: task)
        viewModel.addSubtask(title: "C", to: task)

        viewModel.reorderSubtasks(of: task, from: IndexSet(integer: 2), to: 0)

        let sorted = task.subtasks.sorted { $0.sortOrder < $1.sortOrder }
        XCTAssertEqual(sorted.map(\.title), ["C", "A", "B"])
    }

    func testReorderSubtasksSortOrderContiguity() {
        let (_, task) = makeParentTask()
        viewModel.addSubtask(title: "A", to: task)
        viewModel.addSubtask(title: "B", to: task)
        viewModel.addSubtask(title: "C", to: task)

        viewModel.reorderSubtasks(of: task, from: IndexSet(integer: 0), to: 3)

        let sorted = task.subtasks.sorted { $0.sortOrder < $1.sortOrder }
        assertSortOrderConsecutive(sorted)
    }

    func testDeleteSubtaskThenAddNew() {
        let (_, task) = makeParentTask()
        viewModel.addSubtask(title: "A", to: task)
        viewModel.addSubtask(title: "B", to: task)

        let sorted = task.subtasks.sorted { $0.sortOrder < $1.sortOrder }
        viewModel.deleteSubtask(sorted.first!, from: task)

        viewModel.addSubtask(title: "C", to: task)

        // New subtask should have sortOrder = max of remaining + 1
        let newSub = task.subtasks.sorted { $0.sortOrder < $1.sortOrder }.last!
        XCTAssertEqual(newSub.title, "C")
        XCTAssertTrue(newSub.sortOrder > 0)
    }

    func testSubtasksDeletedWhenTaskDeleted() throws {
        let (col, task) = makeParentTask()
        viewModel.addSubtask(title: "Sub 1", to: task)
        viewModel.addSubtask(title: "Sub 2", to: task)
        viewModel.addSubtask(title: "Sub 3", to: task)

        viewModel.deleteTask(task)

        let subtasks = try container.mainContext.fetch(FetchDescriptor<Subtask>())
        XCTAssertEqual(subtasks.count, 0)
        XCTAssertEqual(viewModel.sortedTasks(for: col).count, 0)
    }

    func testSubtasksSurviveTaskMove() {
        let (_, task) = makeParentTask()
        viewModel.addSubtask(title: "Sub A", to: task)
        viewModel.addSubtask(title: "Sub B", to: task)

        let sub = task.subtasks.first!
        viewModel.toggleSubtask(sub) // Mark one complete

        let col2 = viewModel.sortedColumns[1]
        viewModel.moveTask(withID: task.id.uuidString, to: col2)

        // Subtasks should survive the move
        XCTAssertEqual(task.subtasks.count, 2)
        let titles = task.subtasks.sorted { $0.sortOrder < $1.sortOrder }.map(\.title)
        XCTAssertEqual(titles, ["Sub A", "Sub B"])
        // Completion state should be preserved
        XCTAssertTrue(task.subtasks.contains(where: { $0.isCompleted }))
    }
}
