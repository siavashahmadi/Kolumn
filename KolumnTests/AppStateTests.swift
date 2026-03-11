import XCTest
@testable import Kolumn

final class AppStateTests: XCTestCase {

    func testInitialStateAllNilOrFalse() {
        let state = AppState()
        XCTAssertNil(state.selectedBoardID)
        XCTAssertNil(state.selectedTaskID)
        XCTAssertNil(state.selectedColumnIndex)
        XCTAssertFalse(state.isCommandPaletteOpen)
        XCTAssertFalse(state.showNewBoardSheet)
        XCTAssertFalse(state.showArchivedTasks)
    }

    func testSelectBoardAndTask() {
        let state = AppState()
        let taskID = UUID()
        state.selectedTaskID = taskID
        state.selectedColumnIndex = 2

        XCTAssertEqual(state.selectedTaskID, taskID)
        XCTAssertEqual(state.selectedColumnIndex, 2)
    }

    func testClearSelectionOnBoardChange() {
        let state = AppState()
        state.selectedTaskID = UUID()
        state.selectedColumnIndex = 1

        // Change board — documents that task is NOT auto-cleared (potential bug)
        state.selectedBoardID = nil
        XCTAssertNotNil(state.selectedTaskID, "Task selection is not auto-cleared when board changes — potential bug")
    }

    func testCommandPaletteToggle() {
        let state = AppState()
        XCTAssertFalse(state.isCommandPaletteOpen)

        state.isCommandPaletteOpen = true
        XCTAssertTrue(state.isCommandPaletteOpen)

        state.isCommandPaletteOpen = false
        XCTAssertFalse(state.isCommandPaletteOpen)
    }

    func testMultipleStateChanges() {
        let state = AppState()
        state.selectedTaskID = UUID()
        state.selectedColumnIndex = 3
        state.isCommandPaletteOpen = true
        state.showNewBoardSheet = true
        state.showArchivedTasks = true

        // Clear all
        state.selectedTaskID = nil
        state.selectedColumnIndex = nil
        state.isCommandPaletteOpen = false
        state.showNewBoardSheet = false
        state.showArchivedTasks = false

        XCTAssertNil(state.selectedTaskID)
        XCTAssertNil(state.selectedColumnIndex)
        XCTAssertFalse(state.isCommandPaletteOpen)
        XCTAssertFalse(state.showNewBoardSheet)
        XCTAssertFalse(state.showArchivedTasks)
    }

    func testSelectedColumnIndexNoBoundsCheck() {
        let state = AppState()
        // Documents: no validation — any value accepted
        state.selectedColumnIndex = -1
        XCTAssertEqual(state.selectedColumnIndex, -1)

        state.selectedColumnIndex = 99999
        XCTAssertEqual(state.selectedColumnIndex, 99999)
    }
}
