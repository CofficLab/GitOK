import Foundation
import Testing
@testable import PluginGitSmartMerge

@Suite("MergeSelectionStore")
struct MergeSelectionStoreTests {
    @Test("saves and loads selections")
    func savesAndLoadsSelections() throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let repository = directory.appendingPathComponent("repo", isDirectory: true)
        let store = MergeSelectionStore(storageDirectory: directory)
        let selection = MergeSelection(sourceBranchName: "feature/login", targetBranchName: "dev")

        store.save(selection, for: repository)

        #expect(store.selection(for: repository) == selection)
    }

    @Test("isolates selections by repository")
    func isolatesSelectionsByRepository() throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let firstRepository = directory.appendingPathComponent("first", isDirectory: true)
        let secondRepository = directory.appendingPathComponent("second", isDirectory: true)
        let store = MergeSelectionStore(storageDirectory: directory)
        let firstSelection = MergeSelection(sourceBranchName: "feature/a", targetBranchName: "main")
        let secondSelection = MergeSelection(sourceBranchName: "release", targetBranchName: "dev")

        store.save(firstSelection, for: firstRepository)
        store.save(secondSelection, for: secondRepository)

        #expect(store.selection(for: firstRepository) == firstSelection)
        #expect(store.selection(for: secondRepository) == secondSelection)
    }

    @Test("invalid or missing files return no selection")
    func invalidOrMissingFilesReturnNoSelection() throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let repository = directory.appendingPathComponent("repo", isDirectory: true)
        let store = MergeSelectionStore(storageDirectory: directory)
        #expect(store.selection(for: repository) == nil)

        let fileURL = directory.appendingPathComponent("merge-selection.json")
        try Data("not-json".utf8).write(to: fileURL)
        #expect(store.selection(for: repository) == nil)
    }

    private func makeDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MergeSelectionStore-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
