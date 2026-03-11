import XCTest
import SwiftData
@testable import Kolumn

@MainActor
final class ModelTests: XCTestCase {

    private var container: ModelContainer!

    override func setUp() async throws {
        try await super.setUp()
        container = try makeTestContainer()
    }

    // MARK: - Board

    func testBoardInitializesWithDefaults() {
        let board = Board(name: "My Board")
        XCTAssertNotNil(board.id)
        XCTAssertEqual(board.name, "My Board")
        XCTAssertEqual(board.emoji, "📋")
        XCTAssertEqual(board.sortOrder, 0)
        XCTAssertTrue(board.columns.isEmpty)
        XCTAssertTrue(board.createdAt.timeIntervalSinceNow > -5)
    }

    func testBoardCustomEmoji() {
        let board = Board(name: "Work", emoji: "💼")
        XCTAssertEqual(board.emoji, "💼")
    }

    // MARK: - Column

    func testColumnInitializesWithDefaults() {
        let col = Column(title: "Backlog", sortOrder: 0)
        XCTAssertNotNil(col.id)
        XCTAssertEqual(col.title, "Backlog")
        XCTAssertEqual(col.sortOrder, 0)
        XCTAssertEqual(col.colorHex, "#C3B1E1")
        XCTAssertTrue(col.tasks.isEmpty)
        XCTAssertNil(col.board)
    }

    func testColumnDefaultColumnsFactory() {
        let cols = Column.defaultColumns()
        XCTAssertEqual(cols.count, 5)
        XCTAssertEqual(cols.map(\.title), ["Haven't Started", "In Progress", "Blocked", "In Review", "Done"])
        XCTAssertEqual(cols.map(\.sortOrder), [0, 1, 2, 3, 4])
    }

    // MARK: - TaskItem

    func testTaskItemInitializesWithDefaults() {
        let task = TaskItem(title: "Fix bug")
        XCTAssertNotNil(task.id)
        XCTAssertEqual(task.title, "Fix bug")
        XCTAssertEqual(task.notes, "")
        XCTAssertNil(task.dueDate)
        XCTAssertEqual(task.priority, .medium)
        XCTAssertEqual(task.sortOrder, 0)
        XCTAssertFalse(task.isArchived)
        XCTAssertNil(task.reminderOffset)
        XCTAssertTrue(task.createdAt.timeIntervalSinceNow > -5)
        XCTAssertNil(task.column)
        XCTAssertTrue(task.tags.isEmpty)
        XCTAssertTrue(task.subtasks.isEmpty)
    }

    func testTaskItemCustomPriority() {
        let task = TaskItem(title: "Urgent", priority: .high)
        XCTAssertEqual(task.priority, .high)
    }

    // MARK: - Tag

    func testTagInitializesWithDefaults() {
        let tag = Tag(name: "Bug", colorHex: "#FF0000")
        XCTAssertNotNil(tag.id)
        XCTAssertEqual(tag.name, "Bug")
        XCTAssertEqual(tag.colorHex, "#FF0000")
        XCTAssertTrue(tag.tasks.isEmpty)
    }

    // MARK: - Subtask

    func testSubtaskInitializesWithDefaults() {
        let subtask = Subtask(title: "Step 1")
        XCTAssertNotNil(subtask.id)
        XCTAssertEqual(subtask.title, "Step 1")
        XCTAssertFalse(subtask.isCompleted)
        XCTAssertEqual(subtask.sortOrder, 0)
        XCTAssertNil(subtask.taskItem)
    }

    func testSubtaskCustomSortOrder() {
        let subtask = Subtask(title: "Step 5", sortOrder: 5)
        XCTAssertEqual(subtask.sortOrder, 5)
    }

    // MARK: - Relationships

    func testBoardColumnRelationship() {
        let context = container.mainContext
        let board = Board(name: "Board")
        context.insert(board)

        let col = Column(title: "Col", sortOrder: 0)
        col.board = board
        board.columns.append(col)
        try? context.save()

        XCTAssertEqual(board.columns.count, 1)
        XCTAssertEqual(board.columns.first?.id, col.id)
        XCTAssertEqual(col.board?.id, board.id)
    }

    func testColumnTaskRelationship() {
        let context = container.mainContext
        let col = Column(title: "Col", sortOrder: 0)
        context.insert(col)

        let task = TaskItem(title: "Task")
        task.column = col
        col.tasks.append(task)
        try? context.save()

        XCTAssertEqual(col.tasks.count, 1)
        XCTAssertEqual(col.tasks.first?.id, task.id)
        XCTAssertEqual(task.column?.id, col.id)
    }

    func testTaskSubtaskRelationship() {
        let context = container.mainContext
        let task = TaskItem(title: "Task")
        context.insert(task)

        let subtask = Subtask(title: "Sub")
        subtask.taskItem = task
        task.subtasks.append(subtask)
        try? context.save()

        XCTAssertEqual(task.subtasks.count, 1)
        XCTAssertEqual(task.subtasks.first?.id, subtask.id)
        XCTAssertEqual(subtask.taskItem?.id, task.id)
    }

    func testTaskTagManyToMany() {
        let context = container.mainContext
        let tag1 = Tag(name: "Bug", colorHex: "#FF0000")
        let tag2 = Tag(name: "Feature", colorHex: "#00FF00")
        let task1 = TaskItem(title: "Task 1")
        let task2 = TaskItem(title: "Task 2")

        context.insert(tag1)
        context.insert(tag2)
        context.insert(task1)
        context.insert(task2)

        task1.tags.append(contentsOf: [tag1, tag2])
        task2.tags.append(contentsOf: [tag1, tag2])
        try? context.save()

        XCTAssertEqual(task1.tags.count, 2)
        XCTAssertEqual(task2.tags.count, 2)
        XCTAssertEqual(tag1.tasks.count, 2)
        XCTAssertEqual(tag2.tasks.count, 2)
    }

    // MARK: - Cascade Deletes

    func testCascadeDeleteBoardDeletesColumns() throws {
        let context = container.mainContext
        let board = Board(name: "Board")
        context.insert(board)

        for i in 0..<3 {
            let col = Column(title: "Col \(i)", sortOrder: i)
            col.board = board
            board.columns.append(col)
        }
        try context.save()

        context.delete(board)
        try context.save()

        let columns = try context.fetch(FetchDescriptor<Column>())
        XCTAssertEqual(columns.count, 0)
    }

    func testCascadeDeleteBoardDeletesTasksAndSubtasks() throws {
        let context = container.mainContext
        let board = Board(name: "Board")
        context.insert(board)

        let col = Column(title: "Col", sortOrder: 0)
        col.board = board
        board.columns.append(col)

        let task = TaskItem(title: "Task")
        task.column = col
        col.tasks.append(task)

        let subtask = Subtask(title: "Sub")
        subtask.taskItem = task
        task.subtasks.append(subtask)
        try context.save()

        context.delete(board)
        try context.save()

        XCTAssertEqual(try context.fetch(FetchDescriptor<Column>()).count, 0)
        XCTAssertEqual(try context.fetch(FetchDescriptor<TaskItem>()).count, 0)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Subtask>()).count, 0)
    }

    func testCascadeDeleteColumnDeletesTasks() throws {
        let context = container.mainContext
        let col = Column(title: "Col", sortOrder: 0)
        context.insert(col)

        for i in 0..<3 {
            let task = TaskItem(title: "Task \(i)")
            task.column = col
            col.tasks.append(task)

            for s in 0..<2 {
                let sub = Subtask(title: "Sub \(s)", sortOrder: s)
                sub.taskItem = task
                task.subtasks.append(sub)
            }
        }
        try context.save()

        context.delete(col)
        try context.save()

        XCTAssertEqual(try context.fetch(FetchDescriptor<TaskItem>()).count, 0)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Subtask>()).count, 0)
    }

    func testCascadeDeleteTaskDeletesSubtasks() throws {
        let context = container.mainContext
        let col = Column(title: "Col", sortOrder: 0)
        context.insert(col)

        let task = TaskItem(title: "Task")
        task.column = col
        col.tasks.append(task)

        for i in 0..<5 {
            let sub = Subtask(title: "Sub \(i)", sortOrder: i)
            sub.taskItem = task
            task.subtasks.append(sub)
        }
        try context.save()

        context.delete(task)
        try context.save()

        XCTAssertEqual(try context.fetch(FetchDescriptor<Subtask>()).count, 0)
        // Column should survive
        XCTAssertEqual(try context.fetch(FetchDescriptor<Column>()).count, 1)
    }

    func testDeleteTagDoesNotDeleteTasks() throws {
        let context = container.mainContext
        let tag = Tag(name: "Bug", colorHex: "#FF0000")
        context.insert(tag)

        for i in 0..<3 {
            let task = TaskItem(title: "Task \(i)")
            context.insert(task)
            task.tags.append(tag)
        }
        try context.save()

        context.delete(tag)
        try context.save()

        let tasks = try context.fetch(FetchDescriptor<TaskItem>())
        XCTAssertEqual(tasks.count, 3)
    }

    func testDeleteTaskDoesNotDeleteTags() throws {
        let context = container.mainContext
        let task = TaskItem(title: "Task")
        context.insert(task)

        for i in 0..<3 {
            let tag = Tag(name: "Tag \(i)", colorHex: "#00FF00")
            context.insert(tag)
            task.tags.append(tag)
        }
        try context.save()

        context.delete(task)
        try context.save()

        let tags = try context.fetch(FetchDescriptor<Tag>())
        XCTAssertEqual(tags.count, 3)
    }
}
