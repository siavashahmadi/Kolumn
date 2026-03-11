import Foundation
import UserNotifications

enum ReminderOffset: String, CaseIterable, Identifiable {
    case fifteenMinutes = "15min"
    case oneHour = "1hr"
    case oneDay = "1day"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .fifteenMinutes: "15 minutes before"
        case .oneHour: "1 hour before"
        case .oneDay: "1 day before"
        }
    }

    var timeInterval: TimeInterval {
        switch self {
        case .fifteenMinutes: 15 * 60
        case .oneHour: 60 * 60
        case .oneDay: 24 * 60 * 60
        }
    }
}

@MainActor @Observable final class NotificationManager {
    var isAuthorized = false

    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
        } catch {
            print("Notification permission error: \(error.localizedDescription)")
        }
    }

    func scheduleReminder(for task: TaskItem, reminderOffset: ReminderOffset) {
        guard let dueDate = task.dueDate else { return }

        let triggerDate = dueDate.addingTimeInterval(-reminderOffset.timeInterval)
        guard triggerDate > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"
        content.body = task.title
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: task.id.uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("Failed to schedule reminder: \(error.localizedDescription)")
            }
        }
    }

    func cancelReminder(for task: TaskItem) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])
    }
}
