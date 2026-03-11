import Foundation
import SwiftData

enum Priority: String, Codable, CaseIterable, Identifiable {
    case low, medium, high

    var id: String { rawValue }

    var label: String {
        switch self {
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        }
    }
}

@Model final class TaskItem {
    var id: UUID
    var title: String
    var notes: String
    var dueDate: Date?
    var priority: Priority
    var sortOrder: Int
    var isArchived: Bool
    var reminderOffset: String?
    var createdAt: Date
    var column: Column?
    @Relationship var tags: [Tag]
    @Relationship(deleteRule: .cascade, inverse: \Subtask.taskItem)
    var subtasks: [Subtask]

    init(title: String, priority: Priority = .medium) {
        self.id = UUID()
        self.title = title
        self.notes = ""
        self.dueDate = nil
        self.priority = priority
        self.sortOrder = 0
        self.isArchived = false
        self.reminderOffset = nil
        self.createdAt = .now
        self.tags = []
        self.subtasks = []
    }
}
