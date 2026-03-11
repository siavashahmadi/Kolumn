import XCTest
import SwiftData
@testable import Kolumn

@MainActor
final class IntegrationTests: XCTestCase {

    private var container: ModelContainer!

    override func setUp() async throws {
        try await super.setUp()
        container = try makeTestContainer()
    }

    func testFullBoardLifecycle() throws {
        let (board, vm) = makeTestBoard(in: container)

        // Add tasks to each column
        for col in vm.sortedColumns {
            vm.addTask(title: "Task in \(col.title)", to: col)
        }
        XCTAssertEqual(vm.sortedColumns.flatMap({ vm.sortedTasks(for: $0) }).count, 3)

        // Move task from first to second column
        let col1 = vm.sortedColumns[0]
        let col2 = vm.sortedColumns[1]
        let task = vm.sortedTasks(for: col1).first!
        vm.moveTask(withID: task.id.uuidString, to: col2)
        XCTAssertEqual(vm.sortedTasks(for: col1).count, 0)
        XCTAssertEqual(vm.sortedTasks(for: col2).count, 2)

        // Archive one
        vm.archiveTask(vm.sortedTasks(for: col2).first!)
        XCTAssertEqual(vm.sortedTasks(for: col2).count, 1) // Default hides archived

        // Delete a column
        vm.deleteColumn(vm.sortedColumns.last!)
        XCTAssertEqual(vm.sortedColumns.count, 2)

        // Board should still be accessible
        XCTAssertEqual(board.columns.count, 2)
    }

    func testTaskFullLifecycle() throws {
        let (_, vm) = makeTestBoard(in: container)
        let col1 = vm.sortedColumns[0]
        let col2 = vm.sortedColumns[1]

        // Create
        vm.addTask(title: "Lifecycle Task", to: col1)
        let task = vm.sortedTasks(for: col1).first!

        // Edit properties
        task.notes = "Some notes"
        task.priority = .high
        task.dueDate = Date.now.addingTimeInterval(86400)

        // Add subtasks
        vm.addSubtask(title: "Step 1", to: task)
        vm.addSubtask(title: "Step 2", to: task)
        XCTAssertEqual(task.subtasks.count, 2)

        // Toggle subtask
        let sub = task.subtasks.first!
        vm.toggleSubtask(sub)
        XCTAssertTrue(sub.isCompleted)

        // Add tags
        let tag = Tag(name: "Important", colorHex: "#FF0000")
        container.mainContext.insert(tag)
        task.tags.append(tag)

        // Move to another column
        vm.moveTask(withID: task.id.uuidString, to: col2)
        XCTAssertEqual(task.column?.id, col2.id)
        XCTAssertEqual(task.subtasks.count, 2)
        XCTAssertEqual(task.tags.count, 1)

        // Archive
        vm.archiveTask(task)
        XCTAssertTrue(task.isArchived)
        XCTAssertEqual(vm.sortedTasks(for: col2).count, 0)

        // Unarchive
        vm.unarchiveTask(task)
        XCTAssertFalse(task.isArchived)
        XCTAssertEqual(vm.sortedTasks(for: col2).count, 1)

        // Delete
        vm.deleteTask(task)
        XCTAssertEqual(vm.sortedTasks(for: col2).count, 0)
        XCTAssertEqual(try container.mainContext.fetch(FetchDescriptor<Subtask>()).count, 0)
    }

    func testColumnReorganization() {
        let (_, vm) = makeTestBoard(in: container)

        // Add tasks
        for col in vm.sortedColumns {
            vm.addTask(title: "Task-\(col.title)", to: col)
        }

        // Reorder columns multiple times
        vm.reorderColumns(from: IndexSet(integer: 0), to: 3)
        vm.reorderColumns(from: IndexSet(integer: 2), to: 0)

        // Tasks should still be in their correct columns (by column identity, not position)
        for col in vm.sortedColumns {
            let tasks = vm.sortedTasks(for: col)
            XCTAssertEqual(tasks.count, 1)
            XCTAssertEqual(tasks.first?.title, "Task-\(col.title)")
        }
    }

    func testMoveAllTasksToOneColumn() {
        let (_, vm) = makeTestBoard(in: container)

        // Add 5 tasks to each of 3 columns
        for col in vm.sortedColumns {
            for i in 0..<5 {
                vm.addTask(title: "\(col.title)-\(i)", to: col)
            }
        }

        let target = vm.sortedColumns[0]

        // Move all tasks from other columns to target
        for col in vm.sortedColumns where col.id != target.id {
            for task in vm.sortedTasks(for: col) {
                vm.moveTask(withID: task.id.uuidString, to: target)
            }
        }

        XCTAssertEqual(vm.sortedTasks(for: target).count, 15)

        // Other columns should be empty
        for col in vm.sortedColumns where col.id != target.id {
            XCTAssertEqual(vm.sortedTasks(for: col).count, 0)
        }

        // Sort orders should be valid
        let sortOrders = vm.sortedTasks(for: target).map(\.sortOrder)
        XCTAssertEqual(Set(sortOrders).count, 15, "All sortOrders should be unique")
    }

    func testDeleteColumnCascadesNotMoves() throws {
        let (_, vm) = makeTestBoard(in: container)
        let col = vm.sortedColumns.first!

        vm.addTask(title: "Will Die", to: col)
        vm.addTask(title: "Also Dies", to: col)
        vm.addTask(title: "Dies Too", to: col)

        vm.deleteColumn(col)

        // Tasks should be CASCADE DELETED, not moved
        let allTasks = try container.mainContext.fetch(FetchDescriptor<TaskItem>())
        XCTAssertEqual(allTasks.count, 0)
    }

    func testTagWorkflow() throws {
        let tagVM = TagViewModel(modelContext: container.mainContext)
        let (_, vm) = makeTestBoard(in: container)
        let col = vm.sortedColumns.first!

        // Create tags
        tagVM.addTag(name: "Bug", colorHex: "#FF0000")
        tagVM.addTag(name: "Feature", colorHex: "#00FF00")
        tagVM.addTag(name: "Docs", colorHex: "#0000FF")

        // Create tasks and assign tags
        vm.addTask(title: "Fix crash", to: col)
        vm.addTask(title: "Add login", to: col)
        let task1 = vm.sortedTasks(for: col)[0]
        let task2 = vm.sortedTasks(for: col)[1]

        task1.tags.append(tagVM.tags[0]) // Bug
        task2.tags.append(tagVM.tags[1]) // Feature
        task2.tags.append(tagVM.tags[2]) // Docs

        XCTAssertEqual(task1.tags.count, 1)
        XCTAssertEqual(task2.tags.count, 2)

        // Delete the "Bug" tag
        tagVM.deleteTag(tagVM.tags.first(where: { $0.name == "Bug" })!)

        XCTAssertEqual(task1.tags.count, 0)
        XCTAssertEqual(task2.tags.count, 2) // Unaffected
        XCTAssertEqual(tagVM.tags.count, 2)
    }

    func testSubtaskWorkflow() {
        let (_, vm) = makeTestBoard(in: container)
        let col = vm.sortedColumns.first!
        vm.addTask(title: "Parent", to: col)
        let task = vm.sortedTasks(for: col).first!

        // Add 5 subtasks
        for i in 0..<5 {
            vm.addSubtask(title: "Step \(i)", to: task)
        }
        XCTAssertEqual(task.subtasks.count, 5)

        // Reorder
        vm.reorderSubtasks(of: task, from: IndexSet(integer: 0), to: 5)

        // Toggle some
        let sorted = task.subtasks.sorted { $0.sortOrder < $1.sortOrder }
        vm.toggleSubtask(sorted[0])
        vm.toggleSubtask(sorted[2])

        // Delete some
        vm.deleteSubtask(sorted[1], from: task)
        XCTAssertEqual(task.subtasks.count, 4)

        // Add more
        vm.addSubtask(title: "Step 5", to: task)
        vm.addSubtask(title: "Step 6", to: task)
        XCTAssertEqual(task.subtasks.count, 6)

        // Verify completed states survived
        let completed = task.subtasks.filter(\.isCompleted)
        XCTAssertEqual(completed.count, 2)
    }

    func testBoardWithNoColumns() {
        let context = container.mainContext
        let board = Board(name: "Empty")
        context.insert(board)
        let vm = BoardViewModel(board: board, modelContext: context)

        XCTAssertTrue(vm.sortedColumns.isEmpty)
    }

    func testRapidAddAndDelete() throws {
        let (_, vm) = makeTestBoard(in: container)
        let col = vm.sortedColumns.first!

        // Add 50 tasks
        for i in 0..<50 {
            vm.addTask(title: "Task \(i)", to: col)
        }
        XCTAssertEqual(vm.sortedTasks(for: col).count, 50)

        // Delete all 50
        while let task = vm.sortedTasks(for: col).first {
            vm.deleteTask(task)
        }
        XCTAssertEqual(vm.sortedTasks(for: col).count, 0)

        // Verify no orphans
        XCTAssertEqual(try container.mainContext.fetch(FetchDescriptor<TaskItem>()).count, 0)
    }

    func testMultipleBoardsIsolation() {
        let context = container.mainContext

        let board1 = Board(name: "Board 1")
        let board2 = Board(name: "Board 2")
        context.insert(board1)
        context.insert(board2)

        let col1 = Column(title: "Col A", sortOrder: 0)
        col1.board = board1
        board1.columns.append(col1)

        let col2 = Column(title: "Col B", sortOrder: 0)
        col2.board = board2
        board2.columns.append(col2)

        let vm1 = BoardViewModel(board: board1, modelContext: context)
        let vm2 = BoardViewModel(board: board2, modelContext: context)

        vm1.addTask(title: "Task on B1", to: col1)
        vm2.addTask(title: "Task on B2", to: col2)

        // Modify board 1
        vm1.deleteTask(vm1.sortedTasks(for: col1).first!)

        // Board 2 should be unaffected
        XCTAssertEqual(vm2.sortedTasks(for: col2).count, 1)
        XCTAssertEqual(vm2.sortedTasks(for: col2).first?.title, "Task on B2")
    }

    func testArchiveFilterDuringMoves() {
        let (_, vm) = makeTestBoard(in: container)
        let col1 = vm.sortedColumns[0]
        let col2 = vm.sortedColumns[1]

        vm.addTask(title: "Active", to: col1)
        vm.addTask(title: "Archived", to: col1)

        // Archive one
        let archivedTask = vm.sortedTasks(for: col1).last!
        vm.archiveTask(archivedTask)

        // Move archived task to col2
        vm.moveTask(withID: archivedTask.id.uuidString, to: col2)

        // col1: 1 active, col2: 0 visible (1 archived)
        XCTAssertEqual(vm.sortedTasks(for: col1).count, 1)
        XCTAssertEqual(vm.sortedTasks(for: col2).count, 0)
        XCTAssertEqual(vm.sortedTasks(for: col2, showArchived: true).count, 1)
    }

    func testEmptyStatesAfterDeletion() throws {
        let (board, vm) = makeTestBoard(in: container)
        let col = vm.sortedColumns.first!

        vm.addTask(title: "Task", to: col)
        let task = vm.sortedTasks(for: col).first!
        vm.addSubtask(title: "Sub", to: task)

        // Delete everything
        container.mainContext.delete(board)
        try container.mainContext.save()

        XCTAssertEqual(try container.mainContext.fetch(FetchDescriptor<Board>()).count, 0)
        XCTAssertEqual(try container.mainContext.fetch(FetchDescriptor<Column>()).count, 0)
        XCTAssertEqual(try container.mainContext.fetch(FetchDescriptor<TaskItem>()).count, 0)
        XCTAssertEqual(try container.mainContext.fetch(FetchDescriptor<Subtask>()).count, 0)
    }

    func testCreateBoardWithDefaultColumns() throws {
        let context = container.mainContext
        let board = Board(name: "Default Board")
        context.insert(board)

        let defaults = Column.defaultColumns()
        for col in defaults {
            col.board = board
            board.columns.append(col)
        }
        try context.save()

        let vm = BoardViewModel(board: board, modelContext: context)
        XCTAssertEqual(vm.sortedColumns.count, 5)
        XCTAssertEqual(vm.sortedColumns.map(\.title),
                       ["Haven't Started", "In Progress", "Blocked", "In Review", "Done"])
        assertSortOrderConsecutive(vm.sortedColumns)
    }
}
