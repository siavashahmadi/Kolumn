import XCTest
import SwiftData
@testable import Kolumn

@MainActor
final class DataIntegrityTests: XCTestCase {

    private var container: ModelContainer!

    override func setUp() async throws {
        try await super.setUp()
        container = try makeTestContainer()
    }

    // MARK: - Cascade Delete Orphan Checks

    func testCascadeDeleteBoardNoOrphanedColumns() throws {
        let (board, vm) = makeTestBoard(in: container)
        vm.addColumn(title: "Extra 1")
        vm.addColumn(title: "Extra 2")

        container.mainContext.delete(board)
        try container.mainContext.save()

        let columns = try container.mainContext.fetch(FetchDescriptor<Column>())
        XCTAssertEqual(columns.count, 0)
    }

    func testCascadeDeleteBoardNoOrphanedTasks() throws {
        let (board, vm) = makeTestBoard(in: container)
        for col in vm.sortedColumns {
            vm.addTask(title: "Task in \(col.title)", to: col)
        }

        container.mainContext.delete(board)
        try container.mainContext.save()

        XCTAssertEqual(try container.mainContext.fetch(FetchDescriptor<TaskItem>()).count, 0)
    }

    func testCascadeDeleteBoardNoOrphanedSubtasks() throws {
        let (board, vm) = makeTestBoard(in: container)
        let col = vm.sortedColumns.first!
        vm.addTask(title: "Parent", to: col)
        let task = vm.sortedTasks(for: col).first!
        vm.addSubtask(title: "Sub 1", to: task)
        vm.addSubtask(title: "Sub 2", to: task)

        container.mainContext.delete(board)
        try container.mainContext.save()

        XCTAssertEqual(try container.mainContext.fetch(FetchDescriptor<Subtask>()).count, 0)
    }

    func testCascadeDeleteColumnNoOrphanedTasks() throws {
        let (_, vm) = makeTestBoard(in: container)
        let col1 = vm.sortedColumns[0]
        let col2 = vm.sortedColumns[1]

        vm.addTask(title: "Task A", to: col1)
        vm.addTask(title: "Task B", to: col1)
        vm.addTask(title: "Task C", to: col2)

        vm.deleteColumn(col1)

        let tasks = try container.mainContext.fetch(FetchDescriptor<TaskItem>())
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.title, "Task C")
    }

    // MARK: - Many-to-Many Cleanup

    func testTagDeletionCleansUpManyToMany() throws {
        let context = container.mainContext
        let tag = Tag(name: "Shared", colorHex: "#FF0000")
        context.insert(tag)

        var tasks: [TaskItem] = []
        for i in 0..<5 {
            let task = TaskItem(title: "Task \(i)")
            context.insert(task)
            task.tags.append(tag)
            tasks.append(task)
        }
        try context.save()

        context.delete(tag)
        try context.save()

        for task in tasks {
            XCTAssertFalse(task.tags.contains(where: { $0.name == "Shared" }),
                          "Task '\(task.title)' should no longer reference deleted tag")
        }
    }

    func testTaskDeletionCleansUpManyToMany() throws {
        let context = container.mainContext
        let task = TaskItem(title: "To Delete")
        context.insert(task)

        var tags: [Tag] = []
        for i in 0..<5 {
            let tag = Tag(name: "Tag \(i)", colorHex: "#00FF00")
            context.insert(tag)
            task.tags.append(tag)
            tags.append(tag)
        }
        try context.save()

        context.delete(task)
        try context.save()

        for tag in tags {
            XCTAssertFalse(tag.tasks.contains(where: { $0.title == "To Delete" }),
                          "Tag '\(tag.name)' should no longer reference deleted task")
        }
    }

    // MARK: - Move Preserves Data

    func testMoveTaskPreservesSubtasks() {
        let (_, vm) = makeTestBoard(in: container)
        let col1 = vm.sortedColumns[0]
        let col2 = vm.sortedColumns[1]

        vm.addTask(title: "Parent", to: col1)
        let task = vm.sortedTasks(for: col1).first!
        vm.addSubtask(title: "A", to: task)
        vm.addSubtask(title: "B", to: task)
        vm.addSubtask(title: "C", to: task)
        vm.toggleSubtask(task.subtasks.first!)

        vm.moveTask(withID: task.id.uuidString, to: col2)

        XCTAssertEqual(task.subtasks.count, 3)
        let sorted = task.subtasks.sorted { $0.sortOrder < $1.sortOrder }
        XCTAssertEqual(sorted.map(\.title), ["A", "B", "C"])
        XCTAssertTrue(task.subtasks.contains(where: { $0.isCompleted }))
    }

    func testMoveTaskPreservesTags() throws {
        let context = container.mainContext
        let (_, vm) = makeTestBoard(in: container)
        let col1 = vm.sortedColumns[0]
        let col2 = vm.sortedColumns[1]

        vm.addTask(title: "Tagged", to: col1)
        let task = vm.sortedTasks(for: col1).first!

        let tag1 = Tag(name: "Bug", colorHex: "#FF0000")
        let tag2 = Tag(name: "Feature", colorHex: "#00FF00")
        context.insert(tag1)
        context.insert(tag2)
        task.tags.append(contentsOf: [tag1, tag2])
        try context.save()

        vm.moveTask(withID: task.id.uuidString, to: col2)

        XCTAssertEqual(task.tags.count, 2)
        XCTAssertTrue(task.tags.contains(where: { $0.name == "Bug" }))
        XCTAssertTrue(task.tags.contains(where: { $0.name == "Feature" }))
    }

    func testMoveTaskPreservesMetadata() {
        let (_, vm) = makeTestBoard(in: container)
        let col1 = vm.sortedColumns[0]
        let col2 = vm.sortedColumns[1]

        vm.addTask(title: "Detailed", to: col1)
        let task = vm.sortedTasks(for: col1).first!
        task.notes = "Important notes"
        task.dueDate = Date.now.addingTimeInterval(86400)
        task.priority = .high
        task.reminderOffset = "1hr"

        let notes = task.notes
        let dueDate = task.dueDate
        let priority = task.priority
        let reminder = task.reminderOffset

        vm.moveTask(withID: task.id.uuidString, to: col2)

        XCTAssertEqual(task.notes, notes)
        XCTAssertEqual(task.dueDate, dueDate)
        XCTAssertEqual(task.priority, priority)
        XCTAssertEqual(task.reminderOffset, reminder)
    }

    // MARK: - Sort Order Consistency

    func testDeleteAndReaddColumn() {
        let (_, vm) = makeTestBoard(in: container)
        let deletedTitle = vm.sortedColumns.first!.title

        vm.deleteColumn(vm.sortedColumns.first!)
        vm.addColumn(title: deletedTitle)

        let readded = vm.sortedColumns.last!
        XCTAssertEqual(readded.title, deletedTitle)
        // Should be a new instance (new UUID)
        XCTAssertNotEqual(readded.sortOrder, 0) // Not the original sortOrder
    }

    func testSortOrderAfterMultipleDeletes() {
        let (_, vm) = makeTestBoard(in: container)
        let col = vm.sortedColumns.first!

        for i in 0..<5 {
            vm.addTask(title: "Task \(i)", to: col)
        }

        // Delete tasks at positions 0, 2, 4 (every other)
        let tasks = vm.sortedTasks(for: col)
        vm.deleteTask(tasks[4])
        vm.deleteTask(tasks[2])
        vm.deleteTask(tasks[0])

        let remaining = vm.sortedTasks(for: col)
        XCTAssertEqual(remaining.count, 2)
        // SortOrders may have gaps (1, 3) — documenting behavior
        for task in remaining {
            XCTAssertGreaterThanOrEqual(task.sortOrder, 0)
        }
    }

    func testSortOrderAfterMoveAndDelete() {
        let (_, vm) = makeTestBoard(in: container)
        let col = vm.sortedColumns.first!

        vm.addTask(title: "A", to: col)
        vm.addTask(title: "B", to: col)
        vm.addTask(title: "C", to: col)

        // Move first to position 2
        let first = vm.sortedTasks(for: col).first!
        vm.moveTask(withID: first.id.uuidString, to: col, at: 2)

        // Delete the middle task
        let middle = vm.sortedTasks(for: col)[1]
        vm.deleteTask(middle)

        let remaining = vm.sortedTasks(for: col)
        XCTAssertEqual(remaining.count, 2)
    }

    func testBoardColumnCountAfterBulkOps() {
        let (_, vm) = makeTestBoard(in: container)
        // Start with 3

        // Add 5 more
        for i in 0..<5 { vm.addColumn(title: "New \(i)") }
        XCTAssertEqual(vm.sortedColumns.count, 8)

        // Delete 2
        vm.deleteColumn(vm.sortedColumns[0])
        vm.deleteColumn(vm.sortedColumns[0])
        XCTAssertEqual(vm.sortedColumns.count, 6)

        // Add 3 more
        for i in 0..<3 { vm.addColumn(title: "Extra \(i)") }
        XCTAssertEqual(vm.sortedColumns.count, 9)

        // Delete 1
        vm.deleteColumn(vm.sortedColumns.last!)
        XCTAssertEqual(vm.sortedColumns.count, 8)
    }

    func testContextSaveVerification() throws {
        let (_, vm) = makeTestBoard(in: container)
        let col = vm.sortedColumns.first!

        // Add task
        vm.addTask(title: "Persisted", to: col)

        // Verify via fresh fetch
        let tasks = try container.mainContext.fetch(FetchDescriptor<TaskItem>())
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.title, "Persisted")

        // Delete it
        vm.deleteTask(vm.sortedTasks(for: col).first!)

        // Verify deletion persisted
        let afterDelete = try container.mainContext.fetch(FetchDescriptor<TaskItem>())
        XCTAssertEqual(afterDelete.count, 0)
    }
}
