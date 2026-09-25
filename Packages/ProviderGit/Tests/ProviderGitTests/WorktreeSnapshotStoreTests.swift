import Foundation
import KitGit
import Testing
@testable import ProviderGit

@Suite("WorktreeSnapshotStore")
struct WorktreeSnapshotStoreTests {
    @Test("Invalidation preserves the latest snapshot for immediate display")
    func invalidationPreservesLatestSnapshot() throws {
        let store = WorktreeSnapshotStore()
        let repository = URL(fileURLWithPath: "/tmp/provider-git-snapshot-tests")
        let snapshot = GitWorktreeSnapshot(
            entries: [GitStatusEntry(path: "README.md", stagedStatus: " ", worktreeStatus: "M")],
            branch: "main"
        )

        _ = try store.load(repository: repository) { snapshot }
        store.invalidate(repository: repository)

        #expect(store.cached(repository: repository) == snapshot)
    }

    @Test("A stale snapshot is not used as the result of a fresh load")
    func staleSnapshotDoesNotSatisfyLoad() throws {
        let store = WorktreeSnapshotStore()
        let repository = URL(fileURLWithPath: "/tmp/provider-git-snapshot-tests")
        let previous = GitWorktreeSnapshot(entries: [], branch: "main")
        let current = GitWorktreeSnapshot(
            entries: [GitStatusEntry(path: "Sources/App.swift", stagedStatus: "M", worktreeStatus: " ")],
            branch: "main"
        )

        _ = try store.load(repository: repository) { previous }
        store.invalidate(repository: repository)
        let loaded = try store.load(repository: repository) { current }

        #expect(loaded == current)
        #expect(store.cached(repository: repository) == current)
    }
}
