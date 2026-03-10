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
    var createdAt: Date
    var column: Column?
    @Relationship var tags: [Tag]

    init(title: String, priority: Priority = .medium) {
        self.id = UUID()
        self.title = title
        self.notes = ""
        self.dueDate = nil
        self.priority = priority
        self.sortOrder = 0
        self.createdAt = .now
        self.tags = []
    }
}
