import Foundation
import SwiftData

@Model final class Board {
    var id: UUID
    var name: String
    var emoji: String
    var createdAt: Date
    var sortOrder: Int
    @Relationship(deleteRule: .cascade, inverse: \Column.board)
    var columns: [Column]

    init(name: String, emoji: String = "📋") {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.createdAt = .now
        self.sortOrder = 0
        self.columns = []
    }
}
