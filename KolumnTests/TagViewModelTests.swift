import XCTest
import SwiftData
@testable import Kolumn

@MainActor
final class TagViewModelTests: XCTestCase {

    private var container: ModelContainer!
    private var tagVM: TagViewModel!

    override func setUp() async throws {
        try await super.setUp()
        container = try makeTestContainer()
        tagVM = TagViewModel(modelContext: container.mainContext)
    }

    func testInitFetchesTags() {
        // Fresh context = no tags
        XCTAssertTrue(tagVM.tags.isEmpty)
    }

    func testAddTagIncreasesCount() {
        tagVM.addTag(name: "Bug", colorHex: "#FF0000")
        XCTAssertEqual(tagVM.tags.count, 1)
    }

    func testAddTagStoresNameAndColor() {
        tagVM.addTag(name: "Feature", colorHex: "#00FF00")
        let tag = tagVM.tags.first!
        XCTAssertEqual(tag.name, "Feature")
        XCTAssertEqual(tag.colorHex, "#00FF00")
    }

    func testAddMultipleTags() {
        for i in 0..<5 {
            tagVM.addTag(name: "Tag \(i)", colorHex: "#AABB\(i)C")
        }
        XCTAssertEqual(tagVM.tags.count, 5)
    }

    func testAddTagSortedAlphabetically() {
        tagVM.addTag(name: "Zebra", colorHex: "#000000")
        tagVM.addTag(name: "Alpha", colorHex: "#000000")
        tagVM.addTag(name: "Middle", colorHex: "#000000")

        XCTAssertEqual(tagVM.tags.map(\.name), ["Alpha", "Middle", "Zebra"])
    }

    func testDeleteTag() {
        tagVM.addTag(name: "Bug", colorHex: "#FF0000")
        let tag = tagVM.tags.first!
        tagVM.deleteTag(tag)
        XCTAssertTrue(tagVM.tags.isEmpty)
    }

    func testDeleteTagFromMiddle() {
        tagVM.addTag(name: "A", colorHex: "#000000")
        tagVM.addTag(name: "B", colorHex: "#000000")
        tagVM.addTag(name: "C", colorHex: "#000000")

        let middle = tagVM.tags.first(where: { $0.name == "B" })!
        tagVM.deleteTag(middle)

        XCTAssertEqual(tagVM.tags.count, 2)
        XCTAssertEqual(tagVM.tags.map(\.name), ["A", "C"])
    }

    func testDeleteAllTags() {
        tagVM.addTag(name: "A", colorHex: "#000000")
        tagVM.addTag(name: "B", colorHex: "#000000")
        tagVM.addTag(name: "C", colorHex: "#000000")

        for tag in tagVM.tags {
            tagVM.deleteTag(tag)
        }
        XCTAssertTrue(tagVM.tags.isEmpty)
    }

    func testFetchTagsRefreshesFromContext() {
        // Insert tag directly, bypassing ViewModel
        let tag = Tag(name: "Direct", colorHex: "#123456")
        container.mainContext.insert(tag)
        try? container.mainContext.save()

        // ViewModel shouldn't see it yet (it fetched at init)
        // But after explicit fetch, it should appear
        tagVM.fetchTags()
        XCTAssertEqual(tagVM.tags.count, 1)
        XCTAssertEqual(tagVM.tags.first?.name, "Direct")
    }

    func testDeleteTagPreservesAssociatedTasks() throws {
        let tag = Tag(name: "Bug", colorHex: "#FF0000")
        container.mainContext.insert(tag)

        let task = TaskItem(title: "Fix crash")
        container.mainContext.insert(task)
        task.tags.append(tag)
        try container.mainContext.save()

        tagVM.fetchTags()
        tagVM.deleteTag(tagVM.tags.first!)

        let tasks = try container.mainContext.fetch(FetchDescriptor<TaskItem>())
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.title, "Fix crash")
    }

    func testDeleteTagRemovesFromTaskTagsArray() throws {
        let tag = Tag(name: "Bug", colorHex: "#FF0000")
        container.mainContext.insert(tag)

        let task = TaskItem(title: "Task")
        container.mainContext.insert(task)
        task.tags.append(tag)
        try container.mainContext.save()

        XCTAssertEqual(task.tags.count, 1)

        tagVM.fetchTags()
        tagVM.deleteTag(tagVM.tags.first!)

        // After deletion, task should no longer reference the tag
        XCTAssertEqual(task.tags.count, 0)
    }

    func testAddTagWithEmptyName() {
        // Documents: no validation in ViewModel
        tagVM.addTag(name: "", colorHex: "#000000")
        XCTAssertEqual(tagVM.tags.count, 1)
        XCTAssertEqual(tagVM.tags.first?.name, "")
    }

    func testAddTagWithDuplicateName() {
        tagVM.addTag(name: "Bug", colorHex: "#FF0000")
        tagVM.addTag(name: "Bug", colorHex: "#00FF00")
        // Documents: no uniqueness constraint
        XCTAssertEqual(tagVM.tags.count, 2)
    }

    func testTagPersistsThroughNewViewModel() {
        tagVM.addTag(name: "Persistent", colorHex: "#ABCDEF")

        let newVM = TagViewModel(modelContext: container.mainContext)
        XCTAssertEqual(newVM.tags.count, 1)
        XCTAssertEqual(newVM.tags.first?.name, "Persistent")
    }

    func testAddAndDeleteRapidly() {
        // Add 10
        for i in 0..<10 {
            tagVM.addTag(name: "Tag \(i)", colorHex: "#000000")
        }
        XCTAssertEqual(tagVM.tags.count, 10)

        // Delete all 10
        while let tag = tagVM.tags.first {
            tagVM.deleteTag(tag)
        }
        XCTAssertEqual(tagVM.tags.count, 0)

        // Add 5 more
        for i in 0..<5 {
            tagVM.addTag(name: "New \(i)", colorHex: "#FFFFFF")
        }
        XCTAssertEqual(tagVM.tags.count, 5)
    }

    func testMultipleTasksSameTag() throws {
        let tag = Tag(name: "Shared", colorHex: "#FF00FF")
        container.mainContext.insert(tag)

        for i in 0..<3 {
            let task = TaskItem(title: "Task \(i)")
            container.mainContext.insert(task)
            task.tags.append(tag)
        }
        try container.mainContext.save()

        XCTAssertEqual(tag.tasks.count, 3)
    }
}
