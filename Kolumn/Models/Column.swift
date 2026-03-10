import Foundation
import SwiftData

@Model final class Column {
    var id: UUID
    var title: String
    var sortOrder: Int
    var colorHex: String
    var board: Board?
    @Relationship(deleteRule: .cascade, inverse: \TaskItem.column)
    var tasks: [TaskItem]

    init(title: String, sortOrder: Int, colorHex: String = "#C3B1E1") {
        self.id = UUID()
        self.title = title
        self.sortOrder = sortOrder
        self.colorHex = colorHex
        self.tasks = []
    }

    static func defaultColumns() -> [Column] {
        ["Haven't Started", "In Progress", "Blocked", "In Review", "Done"]
            .enumerated()
            .map { Column(title: $1, sortOrder: $0) }
    }
}
