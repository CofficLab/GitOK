import Foundation
import KitGit
import Testing
@testable import PluginGitBranchStatus

@Suite("BranchListCacheStore")
struct BranchListCacheStoreTests {
    @Test("持久化本地与远程分支及当前标记")
    func savesAndLoadsBranches() throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let repository = directory.appendingPathComponent("repo", isDirectory: true)
        BranchListCacheStore(storageDirectory: directory).save(
            [
                GitBranchSummary(name: "main", isRemote: false, isCurrent: true),
                GitBranchSummary(name: "feature/login", isRemote: false, isCurrent: false),
                GitBranchSummary(name: "origin/main", isRemote: true, isCurrent: false),
            ],
            for: repository
        )

        let reloaded = BranchListCacheStore(storageDirectory: directory).branches(for: repository)
        #expect(reloaded == [
            GitBranchSummary(name: "main", isRemote: false, isCurrent: true),
            GitBranchSummary(name: "feature/login", isRemote: false, isCurrent: false),
            GitBranchSummary(name: "origin/main", isRemote: true, isCurrent: false),
        ])
    }

    @Test("不同仓库的缓存互不影响")
    func isolatesBranchesByRepository() throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = BranchListCacheStore(storageDirectory: directory)
        let first = directory.appendingPathComponent("first", isDirectory: true)
        let second = directory.appendingPathComponent("second", isDirectory: true)

        store.save([GitBranchSummary(name: "main", isRemote: false, isCurrent: true)], for: first)
        store.save([GitBranchSummary(name: "dev", isRemote: false, isCurrent: true)], for: second)

        #expect(store.branches(for: first).map(\.name) == ["main"])
        #expect(store.branches(for: second).map(\.name) == ["dev"])
    }

    @Test("缓存缺失或损坏时按无缓存处理")
    func missingOrCorruptedCacheReturnsEmpty() throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let repository = directory.appendingPathComponent("repo", isDirectory: true)
        let store = BranchListCacheStore(storageDirectory: directory)
        #expect(store.branches(for: repository).isEmpty)

        let fileURL = directory.appendingPathComponent("branch-cache.json")
        try Data("not-json".utf8).write(to: fileURL)
        #expect(store.branches(for: repository).isEmpty)
    }

    @Test("保存空列表会移除该仓库的缓存")
    func savingEmptyListClearsCache() throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let repository = directory.appendingPathComponent("repo", isDirectory: true)
        let store = BranchListCacheStore(storageDirectory: directory)
        store.save([GitBranchSummary(name: "main", isRemote: false, isCurrent: true)], for: repository)

        store.save([], for: repository)

        #expect(store.branches(for: repository).isEmpty)
    }

    private func makeDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BranchListCacheStore-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}