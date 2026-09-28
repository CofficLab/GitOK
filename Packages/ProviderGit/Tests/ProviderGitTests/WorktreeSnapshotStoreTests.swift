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

extension WorktreeSnapshotStoreTests {
    @Test("Cancellation before load throws CancellationError")
    func cancellationBeforeLoadThrows() {
        let store = WorktreeSnapshotStore()
        let repository = URL(fileURLWithPath: "/tmp/provider-git-cancel")
        let cancellation = GitProcessCancellation()
        cancellation.cancel()

        #expect(throws: CancellationError.self) {
            try store.load(repository: repository, cancellation: cancellation) {
                GitWorktreeSnapshot(entries: [], branch: "main")
            }
        }
    }

    @Test("Cached returns nil for unknown repository")
    func cachedUnknownReturnsNil() {
        let store = WorktreeSnapshotStore()
        #expect(store.cached(repository: URL(fileURLWithPath: "/tmp/never-loaded")) == nil)
    }

    @Test("Loader error propagates and pending is cleared")
    func loaderErrorPropagates() {
        let store = WorktreeSnapshotStore()
        let repository = URL(fileURLWithPath: "/tmp/provider-git-error")

        enum TestError: Error { case boom }
        #expect(throws: TestError.self) {
            try store.load(repository: repository) { throw TestError.boom }
        }

        // After error, pending is cleared; next call starts fresh
        let snapshot = try? store.load(repository: repository) {
            GitWorktreeSnapshot(entries: [], branch: "main")
        }
        #expect(snapshot?.branch == "main")
    }
}
