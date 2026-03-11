import XCTest
import SwiftData
@testable import Kolumn

@MainActor
final class PerformanceTests: XCTestCase {

    private var container: ModelContainer!

    override func setUp() async throws {
        try await super.setUp()
        container = try makeTestContainer()
    }

    func testPerformanceSortedColumns100() throws {
        let (_, vm) = makePopulatedBoard(in: container, columnCount: 100, tasksPerColumn: 0)

        measure {
            _ = vm.sortedColumns
        }
    }

    func testPerformanceSortedTasks500() throws {
        let (_, vm) = makePopulatedBoard(in: container, columnCount: 1, tasksPerColumn: 500)
        let col = vm.sortedColumns.first!

        measure {
            _ = vm.sortedTasks(for: col)
        }
    }

    func testPerformanceAddTask1000() throws {
        let (_, vm) = makePopulatedBoard(in: container, columnCount: 1, tasksPerColumn: 1000)
        let col = vm.sortedColumns.first!

        measure {
            vm.addTask(title: "New Task", to: col)
        }
    }

    func testPerformanceMoveTaskSearch500() throws {
        let (_, vm) = makePopulatedBoard(in: container, columnCount: 5, tasksPerColumn: 100)

        // Get the last task in the last column (worst-case search)
        let lastCol = vm.sortedColumns.last!
        let lastTask = vm.sortedTasks(for: lastCol).last!
        let targetCol = vm.sortedColumns.first!

        measure {
            vm.moveTask(withID: lastTask.id.uuidString, to: targetCol)
            // Move it back for next iteration
            vm.moveTask(withID: lastTask.id.uuidString, to: lastCol)
        }
    }

    func testPerformanceMoveTaskWithPosition500() throws {
        let (_, vm) = makePopulatedBoard(in: container, columnCount: 1, tasksPerColumn: 500)
        let col = vm.sortedColumns.first!
        let task = vm.sortedTasks(for: col).last!

        measure {
            vm.moveTask(withID: task.id.uuidString, to: col, at: 0)
            // Move back for next iteration
            vm.moveTask(withID: task.id.uuidString, to: col, at: 499)
        }
    }

    func testPerformanceReorderColumns50() throws {
        let (_, vm) = makePopulatedBoard(in: container, columnCount: 50, tasksPerColumn: 0)

        measure {
            vm.reorderColumns(from: IndexSet(integer: 0), to: 50)
        }
    }

    func testPerformanceDeleteColumnWithTasks() throws {
        // Create fresh for each measurement since delete is destructive
        measure {
            let freshContainer = try! makeTestContainer()
            let (_, vm) = makePopulatedBoard(in: freshContainer, columnCount: 3, tasksPerColumn: 200)
            let col = vm.sortedColumns.first!
            vm.deleteColumn(col)
        }
    }

    func testPerformanceTagFetch1000() throws {
        let context = container.mainContext
        for i in 0..<1000 {
            let tag = Tag(name: "Tag \(String(format: "%04d", i))", colorHex: "#000000")
            context.insert(tag)
        }
        try context.save()

        measure {
            let vm = TagViewModel(modelContext: context)
            _ = vm.tags
        }
    }

    func testPerformanceBoardStatsAllTasks() throws {
        let (board, _) = makePopulatedBoard(in: container, columnCount: 5, tasksPerColumn: 200)

        measure {
            // Simulates BoardStatsView.allTasks computed property
            let allTasks = board.columns.flatMap(\.tasks)
            _ = allTasks.count
            _ = allTasks.filter { !$0.isArchived }.count
            _ = allTasks.filter { $0.isArchived }.count
            _ = allTasks.filter { !$0.isArchived && ($0.dueDate.map { $0 < .now } ?? false) }.count
        }
    }

    func testPerformanceSelectedTaskLookup() throws {
        let (_, vm) = makePopulatedBoard(in: container, columnCount: 10, tasksPerColumn: 100)

        // Get a task from the last column (worst-case)
        let lastCol = vm.sortedColumns.last!
        let targetID = vm.sortedTasks(for: lastCol).last!.id

        measure {
            // Simulates BoardView.selectedTask computed property
            var found: TaskItem? = nil
            for col in vm.sortedColumns {
                if let task = vm.sortedTasks(for: col, showArchived: true).first(where: { $0.id == targetID }) {
                    found = task
                    break
                }
            }
            _ = found
        }
    }

    func testPerformanceAddSubtask200() throws {
        let (_, vm) = makeTestBoard(in: container)
        let col = vm.sortedColumns.first!
        let task = makeTaskWithSubtasks(in: vm, column: col, subtaskCount: 200)

        measure {
            vm.addSubtask(title: "Another", to: task)
        }
    }

    func testPerformanceReorderSubtasks100() throws {
        let (_, vm) = makeTestBoard(in: container)
        let col = vm.sortedColumns.first!
        let task = makeTaskWithSubtasks(in: vm, column: col, subtaskCount: 100)

        measure {
            vm.reorderSubtasks(of: task, from: IndexSet(integer: 0), to: 100)
        }
    }
}
