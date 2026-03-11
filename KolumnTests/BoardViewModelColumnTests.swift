import XCTest
import SwiftData
@testable import Kolumn

@MainActor
final class BoardViewModelColumnTests: XCTestCase {

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

    func testAddColumnSortOrderIsMaxPlusOne() {
        let initialMax = viewModel.sortedColumns.last!.sortOrder
        viewModel.addColumn(title: "New")
        XCTAssertEqual(viewModel.sortedColumns.last?.sortOrder, initialMax + 1)
    }

    func testAddColumnSetsBoard() {
        viewModel.addColumn(title: "New")
        let col = viewModel.sortedColumns.last!
        XCTAssertEqual(col.board?.id, board.id)
    }

    func testAddColumnToEmptyBoard() {
        // Delete all existing columns
        for col in viewModel.sortedColumns {
            viewModel.deleteColumn(col)
        }
        XCTAssertEqual(viewModel.sortedColumns.count, 0)

        viewModel.addColumn(title: "First")
        XCTAssertEqual(viewModel.sortedColumns.count, 1)
        XCTAssertEqual(viewModel.sortedColumns.first?.sortOrder, 0)
    }

    func testDeleteColumnRemovesFromBoard() {
        let col = viewModel.sortedColumns.first!
        let colID = col.id
        viewModel.deleteColumn(col)
        XCTAssertFalse(board.columns.contains(where: { $0.id == colID }))
    }

    func testDeleteColumnWithTasks() throws {
        let col = viewModel.sortedColumns.first!
        viewModel.addTask(title: "Task 1", to: col)
        viewModel.addTask(title: "Task 2", to: col)
        viewModel.addTask(title: "Task 3", to: col)

        viewModel.deleteColumn(col)

        let tasks = try container.mainContext.fetch(FetchDescriptor<TaskItem>())
        XCTAssertEqual(tasks.count, 0)
    }

    func testDeleteAllColumns() {
        for col in viewModel.sortedColumns {
            viewModel.deleteColumn(col)
        }
        XCTAssertTrue(board.columns.isEmpty)
        XCTAssertTrue(viewModel.sortedColumns.isEmpty)
    }

    func testRenameColumnEmptyString() {
        let col = viewModel.sortedColumns.first!
        viewModel.renameColumn(col, to: "")
        // Documents current behavior: no validation, empty string is stored
        XCTAssertEqual(col.title, "")
    }

    func testRenameColumnPreservesOtherProperties() {
        let col = viewModel.sortedColumns.first!
        let originalSortOrder = col.sortOrder
        let originalColorHex = col.colorHex
        let originalBoardID = col.board?.id

        viewModel.renameColumn(col, to: "Renamed")

        XCTAssertEqual(col.title, "Renamed")
        XCTAssertEqual(col.sortOrder, originalSortOrder)
        XCTAssertEqual(col.colorHex, originalColorHex)
        XCTAssertEqual(col.board?.id, originalBoardID)
    }

    func testChangeColumnColorUpdatesHex() {
        let col = viewModel.sortedColumns.first!
        viewModel.changeColumnColor(col, to: "#A7D8FF")
        XCTAssertEqual(col.colorHex, "#A7D8FF")
    }

    func testReorderColumnsFirstToLast() {
        let titles = viewModel.sortedColumns.map(\.title)
        XCTAssertEqual(titles, ["To Do", "In Progress", "Done"])

        viewModel.reorderColumns(from: IndexSet(integer: 0), to: 3)

        let reordered = viewModel.sortedColumns.map(\.title)
        XCTAssertEqual(reordered, ["In Progress", "Done", "To Do"])
    }

    func testReorderColumnsLastToFirst() {
        viewModel.reorderColumns(from: IndexSet(integer: 2), to: 0)

        let reordered = viewModel.sortedColumns.map(\.title)
        XCTAssertEqual(reordered, ["Done", "To Do", "In Progress"])
    }

    func testReorderColumnsNoOp() {
        let titlesBefore = viewModel.sortedColumns.map(\.title)
        viewModel.reorderColumns(from: IndexSet(integer: 1), to: 1)
        let titlesAfter = viewModel.sortedColumns.map(\.title)
        XCTAssertEqual(titlesBefore, titlesAfter)
    }

    func testReorderColumnsSortOrderContiguity() {
        viewModel.reorderColumns(from: IndexSet(integer: 0), to: 3)
        assertSortOrderConsecutive(viewModel.sortedColumns)
    }

    func testSortedColumnsOrder() {
        // Manually scramble sortOrders
        let cols = board.columns
        cols[0].sortOrder = 2
        cols[1].sortOrder = 0
        cols[2].sortOrder = 1

        let sorted = viewModel.sortedColumns
        XCTAssertEqual(sorted[0].sortOrder, 0)
        XCTAssertEqual(sorted[1].sortOrder, 1)
        XCTAssertEqual(sorted[2].sortOrder, 2)
    }

    func testAddMultipleColumnsRapidly() {
        for i in 0..<20 {
            viewModel.addColumn(title: "Col \(i)")
        }
        XCTAssertEqual(viewModel.sortedColumns.count, 23) // 3 original + 20 new

        let sortOrders = Set(viewModel.sortedColumns.map(\.sortOrder))
        XCTAssertEqual(sortOrders.count, 23, "All sortOrders should be unique")
    }

    func testDeleteNonexistentColumn() {
        // Create a column that doesn't belong to this board
        let otherCol = Column(title: "Other", sortOrder: 99)
        container.mainContext.insert(otherCol)

        let countBefore = viewModel.sortedColumns.count
        viewModel.deleteColumn(otherCol)
        XCTAssertEqual(viewModel.sortedColumns.count, countBefore)
    }
}
