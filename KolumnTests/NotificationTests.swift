import XCTest
import SwiftData
@testable import Kolumn

@MainActor
final class NotificationTests: XCTestCase {

    private var container: ModelContainer!

    override func setUp() async throws {
        try await super.setUp()
        container = try makeTestContainer()
    }

    // MARK: - ReminderOffset Enum

    func testReminderOffsetTimeIntervals() {
        XCTAssertEqual(ReminderOffset.fifteenMinutes.timeInterval, 900)
        XCTAssertEqual(ReminderOffset.oneHour.timeInterval, 3600)
        XCTAssertEqual(ReminderOffset.oneDay.timeInterval, 86400)
    }

    func testReminderOffsetLabels() {
        XCTAssertEqual(ReminderOffset.fifteenMinutes.label, "15 minutes before")
        XCTAssertEqual(ReminderOffset.oneHour.label, "1 hour before")
        XCTAssertEqual(ReminderOffset.oneDay.label, "1 day before")
    }

    func testReminderOffsetRawValues() {
        XCTAssertEqual(ReminderOffset.fifteenMinutes.rawValue, "15min")
        XCTAssertEqual(ReminderOffset.oneHour.rawValue, "1hr")
        XCTAssertEqual(ReminderOffset.oneDay.rawValue, "1day")
    }

    func testReminderOffsetFromInvalidRawValue() {
        XCTAssertNil(ReminderOffset(rawValue: "bogus"))
        XCTAssertNil(ReminderOffset(rawValue: ""))
        XCTAssertNil(ReminderOffset(rawValue: "5min"))
    }

    // MARK: - Trigger Date Calculation

    func testTriggerDateCalculation15Minutes() {
        let dueDate = Date.now.addingTimeInterval(3600) // 1 hour from now
        let triggerDate = dueDate.addingTimeInterval(-ReminderOffset.fifteenMinutes.timeInterval)

        // Trigger should be 45 minutes from now (1hr - 15min)
        let expected = Date.now.addingTimeInterval(2700)
        XCTAssertEqual(triggerDate.timeIntervalSinceReferenceDate, expected.timeIntervalSinceReferenceDate, accuracy: 1.0)
    }

    func testTriggerDateCalculation1Hour() {
        let dueDate = Date.now.addingTimeInterval(7200) // 2 hours from now
        let triggerDate = dueDate.addingTimeInterval(-ReminderOffset.oneHour.timeInterval)

        // Trigger should be 1 hour from now
        let expected = Date.now.addingTimeInterval(3600)
        XCTAssertEqual(triggerDate.timeIntervalSinceReferenceDate, expected.timeIntervalSinceReferenceDate, accuracy: 1.0)
    }

    func testTriggerDateCalculation1Day() {
        let dueDate = Date.now.addingTimeInterval(172800) // 2 days from now
        let triggerDate = dueDate.addingTimeInterval(-ReminderOffset.oneDay.timeInterval)

        // Trigger should be 1 day from now
        let expected = Date.now.addingTimeInterval(86400)
        XCTAssertEqual(triggerDate.timeIntervalSinceReferenceDate, expected.timeIntervalSinceReferenceDate, accuracy: 1.0)
    }

    // MARK: - Schedule Guard Conditions

    func testScheduleReminderSkipsNilDueDate() {
        let manager = NotificationManager()
        let task = TaskItem(title: "No Due Date")
        task.dueDate = nil
        container.mainContext.insert(task)

        // Should not crash — guard exits early
        manager.scheduleReminder(for: task, reminderOffset: .fifteenMinutes)
    }

    func testScheduleReminderSkipsPastTriggerDate() {
        let manager = NotificationManager()
        let task = TaskItem(title: "Past Due")
        // Due date 5 minutes from now, but offset is 1 day — trigger would be in the past
        task.dueDate = Date.now.addingTimeInterval(300)
        container.mainContext.insert(task)

        // Should not crash — guard catches past trigger date
        manager.scheduleReminder(for: task, reminderOffset: .oneDay)
    }
}
