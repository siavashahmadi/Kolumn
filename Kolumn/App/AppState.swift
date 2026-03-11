import SwiftData
import SwiftUI

@Observable final class AppState {
    var selectedBoardID: PersistentIdentifier?
    var selectedTaskID: UUID?
    var selectedColumnIndex: Int?
    var isCommandPaletteOpen: Bool = false
    var showNewBoardSheet: Bool = false
    var showArchivedTasks: Bool = false
}
