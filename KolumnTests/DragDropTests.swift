import XCTest
import SwiftData
@testable import Kolumn

@MainActor
final class DragDropTests: XCTestCase {

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

    // MARK: - Payload Encoding/Decoding

    func testPayloadEncoding() throws {
        let uuid = UUID().uuidString
        let payload = TaskDragPayload(taskID: uuid)
        let data = try JSONEncoder().encode(payload)
        let json = String(data: data, encoding: .utf8)!
        XCTAssertTrue(json.contains(uuid))
    }

    func testPayloadDecoding() throws {
        let uuid = UUID().uuidString
        let payload = TaskDragPayload(taskID: uuid)
        let data = try JSONEncoder().encode(payload)
        let decoded = try JSONDecoder().decode(TaskDragPayload.self, from: data)
        XCTAssertEqual(decoded.taskID, uuid)
    }

    func testPayloadRoundTrip() throws {
        let original = TaskDragPayload(taskID: UUID().uuidString)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(TaskDragPayload.self, from: data)
        XCTAssertEqual(decoded.taskID, original.taskID)
    }

    func testPayloadWithValidUUID() {
        let uuid = UUID()
        let payload = TaskDragPayload(taskID: uuid.uuidString)
        XCTAssertEqual(payload.taskID, uuid.uuidString)
    }

    func testPayloadWithInvalidUUID() {
        // Payload stores any string — no validation
        let payload = TaskDragPayload(taskID: "not-a-uuid")
        XCTAssertEqual(payload.taskID, "not-a-uuid")
    }

    func testPayloadWithEmptyString() {
        let payload = TaskDragPayload(taskID: "")
        XCTAssertEqual(payload.taskID, "")
    }

    // MARK: - Integration with moveTask

    func testMoveTaskViaPayloadValidID() {
        let col1 = viewModel.sortedColumns[0]
        let col2 = viewModel.sortedColumns[1]
        viewModel.addTask(title: "Drag Me", to: col1)
        let task = viewModel.sortedTasks(for: col1).first!

        let payload = TaskDragPayload(taskID: task.id.uuidString)
        viewModel.moveTask(withID: payload.taskID, to: col2)

        XCTAssertEqual(viewModel.sortedTasks(for: col1).count, 0)
        XCTAssertEqual(viewModel.sortedTasks(for: col2).first?.title, "Drag Me")
    }

    func testMoveTaskViaPayloadInvalidID() {
        let col = viewModel.sortedColumns.first!
        viewModel.addTask(title: "Stay", to: col)

        let payload = TaskDragPayload(taskID: "invalid")
        viewModel.moveTask(withID: payload.taskID, to: col)

        // No crash, task unchanged
        XCTAssertEqual(viewModel.sortedTasks(for: col).count, 1)
    }

    func testMoveTaskViaPayloadNonexistentID() {
        let col = viewModel.sortedColumns.first!
        viewModel.addTask(title: "Stay", to: col)

        let payload = TaskDragPayload(taskID: UUID().uuidString)
        viewModel.moveTask(withID: payload.taskID, to: col)

        XCTAssertEqual(viewModel.sortedTasks(for: col).count, 1)
    }

    func testPayloadCodableConformance() {
        let payload = TaskDragPayload(taskID: "test")
        // Compile-time check expressed as runtime cast
        XCTAssertTrue(payload is Codable)
    }
}
