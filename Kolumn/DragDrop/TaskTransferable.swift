import CoreTransferable
import UniformTypeIdentifiers

struct TaskDragPayload: Codable, Transferable {
    let taskID: String // UUID string for safe Codable transfer

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .taskDragPayload)
    }
}

extension UTType {
    static let taskDragPayload = UTType(exportedAs: "com.kolumn.task-payload")
}
