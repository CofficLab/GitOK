import Foundation
import Testing
@testable import PluginGitSmartMerge

/// `MergeSelectionStore` 的容错路径覆盖。
@Suite("MergeSelectionStore 容错")
struct MergeSelectionStoreResilienceTests {

    @Test("偏好不可写时静默失败，不影响读取")
    func unwritableStorageDirectoryFailsSilently() throws {
        // /dev/null 不是目录，无法在其下创建子目录，写入必然失败。
        let store = MergeSelectionStore(storageDirectory: URL(fileURLWithPath: "/dev/null/nope"))
        let repository = URL(fileURLWithPath: "/tmp/repo")

        store.save(
            MergeSelection(sourceBranchName: "feature/login", targetBranchName: "dev"),
            for: repository
        )

        #expect(store.selection(for: repository) == nil)
    }

    @Test("偏好文件内容损坏时按无选择处理")
    func corruptedPreferenceFileIsIgnored() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MergeSelectionStore-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let fileURL = directory.appendingPathComponent("merge-selection.json")
        try Data("[1, 2, 3]".utf8).write(to: fileURL)

        let store = MergeSelectionStore(storageDirectory: directory)

        #expect(store.selection(for: URL(fileURLWithPath: "/tmp/repo")) == nil)
    }

    @Test("不同仓库的选择互不影响")
    func selectionsAreIsolatedPerRepository() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MergeSelectionStore-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = MergeSelectionStore(storageDirectory: directory)
        let first = URL(fileURLWithPath: "/tmp/first")
        let second = URL(fileURLWithPath: "/tmp/second")

        store.save(MergeSelection(sourceBranchName: "a", targetBranchName: "main"), for: first)
        store.save(MergeSelection(sourceBranchName: "b", targetBranchName: "dev"), for: second)

        #expect(store.selection(for: first)?.sourceBranchName == "a")
        #expect(store.selection(for: second)?.sourceBranchName == "b")
    }
}
