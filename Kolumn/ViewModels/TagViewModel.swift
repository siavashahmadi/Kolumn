import SwiftData
import SwiftUI

@MainActor @Observable final class TagViewModel {
    let modelContext: ModelContext

    var tags: [Tag] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchTags()
    }

    func fetchTags() {
        let descriptor = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.name)])
        tags = (try? modelContext.fetch(descriptor)) ?? []
    }

    func addTag(name: String, colorHex: String) {
        let tag = Tag(name: name, colorHex: colorHex)
        modelContext.insert(tag)
        try? modelContext.save()
        fetchTags()
    }

    func deleteTag(_ tag: Tag) {
        modelContext.delete(tag)
        try? modelContext.save()
        fetchTags()
    }
}
