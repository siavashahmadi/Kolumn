import XCTest
@testable import Kolumn

final class PriorityTests: XCTestCase {

    func testPriorityAllCases() {
        XCTAssertEqual(Priority.allCases, [.low, .medium, .high])
    }

    func testPriorityLabels() {
        XCTAssertEqual(Priority.low.label, "Low")
        XCTAssertEqual(Priority.medium.label, "Medium")
        XCTAssertEqual(Priority.high.label, "High")
    }

    func testPriorityCodableRoundTrip() throws {
        let original = Priority.high
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Priority.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func testPriorityRawValues() {
        XCTAssertEqual(Priority.low.rawValue, "low")
        XCTAssertEqual(Priority.medium.rawValue, "medium")
        XCTAssertEqual(Priority.high.rawValue, "high")
    }

    func testPriorityIdentifiable() {
        XCTAssertEqual(Priority.low.id, "low")
        XCTAssertEqual(Priority.medium.id, "medium")
        XCTAssertEqual(Priority.high.id, "high")
    }
}
