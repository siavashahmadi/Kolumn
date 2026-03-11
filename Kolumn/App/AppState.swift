import SwiftData
import SwiftUI

@Observable final class AppState {
    var selectedBoardID: PersistentIdentifier? {
        didSet {
            if selectedBoardID != oldValue {
                selectedTaskID = nil
                selectedColumnIndex = nil
            }
        }
    }
    var selectedTaskID: UUID?
    var selectedColumnIndex: Int?
    var isCommandPaletteOpen: Bool = false
    var showNewBoardSheet: Bool = false
    var triggerQuickAdd: Bool = false
}
