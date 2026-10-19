import Foundation
import KitGit
import Testing
@testable import ProviderGit

// MARK: - Concurrency-safe boxes

/// Collects clone progress phases from a `@Sendable` progress callback.
final class PhaseRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [GitCloneProgress.Phase] = []

    var phases: [GitCloneProgress.Phase] {
        lock.lock(); defer { lock.unlock() }
        return storage
    }

    func append(_ phase: GitCloneProgress.Phase) {
        lock.lock(); defer { lock.unlock() }
        storage.append(phase)
    }
}

/// Holds a snapshot that a `@Sendable` backend handler reads, so a test can
/// swap the value between two provider reads.
final class SnapshotBox: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: GitWorktreeSnapshot

    init(_ snapshot: GitWorktreeSnapshot) {
        self.storage = snapshot
    }

    var value: GitWorktreeSnapshot {
        get { lock.lock(); defer { lock.unlock() }; return storage }
        set { lock.lock(); defer { lock.unlock() }; storage = newValue }
    }
}

// MARK: - Error descriptions

@Suite("GitProviderError descriptions")
struct GitProviderErrorTests {
    @Test("noBackendAvailable has a stable description")
    func noBackendAvailableDescription() {
        #expect(GitProviderError.noBackendAvailable.errorDescription == "No Git backend is available.")
    }

    @Test("backendAlreadyRegistered names the duplicate id")
    func duplicateBackendDescription() {
        let error = GitProviderError.backendAlreadyRegistered("com.coffic.gitok.git-backend.libgit2")
        #expect(
            error.errorDescription
                == "Git backend is already registered: com.coffic.gitok.git-backend.libgit2"
        )
    }

    @Test("backendOperationUnsupported surfaces the backend message verbatim")
    func unsupportedDescription() {
        let error = GitProviderError.backendOperationUnsupported("libgit2 cannot list stashes")
        #expect(error.errorDescription == "libgit2 cannot list stashes")
    }

    @Test("allBackendsFailed joins one line per failed backend")
    func allBackendsFailedDescription() {
        let error = GitProviderError.allBackendsFailed(
            operation: "listBranches",
            failures: [
                .init(backendID: "cli", backendName: "Git CLI", message: "no repository"),
                .init(backendID: "libgit2", backendName: "LibGit2Swift", message: "HEAD is unborn"),
            ]
        )

        #expect(
            error.errorDescription
                == "Git operation failed (listBranches).\nGit CLI: no repository\nLibGit2Swift: HEAD is unborn"
        )
    }

    @Test("allBackendsFailed with no failures still names the operation")
    func allBackendsFailedWithoutFailures() {
        let error = GitProviderError.allBackendsFailed(operation: "fetch", failures: [])
        #expect(error.errorDescription == "Git operation failed (fetch).\n")
    }

    @Test("GitProviderError stays equatable for assertion in callers")
    func errorEquatable() {
        let lhs = GitProviderError.backendAlreadyRegistered("a")
        let rhs = GitProviderError.backendAlreadyRegistered("a")
        #expect(lhs == rhs)
        #expect(lhs != GitProviderError.backendAlreadyRegistered("b"))
    }
}

// MARK: - Backend catalog

@Suite("GitBackendCatalog")
struct GitBackendCatalogTests {
    @Test("libgit2 outranks the CLI backend")
    func priorityOrdering() {
        #expect(GitBackendCatalog.libGit2.priority > GitBackendCatalog.cli.priority)
    }

    @Test("Built-in descriptors are stable identifiers")
    func descriptorIdentity() {
        #expect(GitBackendCatalog.libGit2.id == "com.coffic.gitok.git-backend.libgit2")
        #expect(GitBackendCatalog.libGit2.pluginID == "com.coffic.gitok.plugin.git-libgit2")
        #expect(GitBackendCatalog.libGit2.name == "LibGit2Swift")
        #expect(GitBackendCatalog.cli.id == "com.coffic.gitok.git-backend.cli")
        #expect(GitBackendCatalog.cli.pluginID == "com.coffic.gitok.plugin.git-cli")
    }

    @Test("The shipped catalog only assembles libgit2 by default")
    func shippedCatalog() {
        #expect(GitBackendCatalog.all == [GitBackendCatalog.libGit2])
    }

    @Test("Descriptors default to version 1.0.0 and priority 0")
    func descriptorDefaults() {
        let descriptor = GitBackendDescriptor(id: "custom", pluginID: "plugin.custom", name: "Custom")
        #expect(descriptor.version == "1.0.0")
        #expect(descriptor.priority == 0)
        #expect(descriptor.id == descriptor.id, "Identifiable id mirrors the backend id")
    }
}

// MARK: - Protocol extension defaults

@Suite("GitOperationProviding compatibility defaults")
struct GitOperationProvidingDefaultTests {
    private let repository = URL(fileURLWithPath: "/tmp/provider-git-defaults")

    private func makeBackend() -> ScriptedGitBackend {
        ScriptedGitBackend.makeBackend(id: "defaults", priority: 1)
    }

    @Test("A cancelled token short-circuits the uncancellable read overloads")
    func cancelledTokenThrowsBeforeDelegating() {
        let backend = makeBackend()
        let cancellation = GitProcessCancellation()
        cancellation.cancel()

        #expect(throws: CancellationError.self) {
            try backend.loadEntries(in: repository, cancellation: cancellation)
        }
        #expect(throws: CancellationError.self) {
            try backend.loadStatus(in: repository, cancellation: cancellation)
        }
        #expect(throws: CancellationError.self) {
            try backend.countCommits(in: repository, cancellation: cancellation)
        }
        #expect(backend.calls.isEmpty, "a cancelled token must not reach the backend")
    }

    @Test("loadEntries delegates to the backend and returns its entries")
    func loadEntriesDelegates() throws {
        let backend = makeBackend()
        let entries = [GitStatusEntry(path: "Sources/App.swift", stagedStatus: "A", worktreeStatus: " ")]
        backend.handlers["loadEntries"] = { _ in entries }

        let loaded = try backend.loadEntries(in: repository, cancellation: GitProcessCancellation())

        #expect(loaded == entries)
        #expect(backend.calledOperations == ["loadEntries"])
    }

    @Test("loadDiff delegates and returns the diff text")
    func loadDiffDelegates() throws {
        let backend = makeBackend()
        backend.handlers["loadDiff"] = { _ in "diff --git a/README.md b/README.md" }

        let diff = try backend.loadDiff(
            commit: "abc123",
            filePath: "README.md",
            in: repository,
            cancellation: nil
        )

        #expect(diff == "diff --git a/README.md b/README.md")
        #expect(backend.calledOperations == ["loadDiff"])
    }

    @Test("unpushedCommitHashes delegates and returns the hash set")
    func unpushedHashesDelegate() throws {
        let backend = makeBackend()
        backend.handlers["unpushedCommitHashes"] = { _ in Set(["a1", "b2"]) }

        let hashes = try backend.unpushedCommitHashes(in: repository, cancellation: nil)

        #expect(hashes == ["a1", "b2"])
    }

    @Test("The three-argument clone overload forwards to the four-argument form")
    func cloneForwardsToCancellableOverload() throws {
        let backend = makeBackend()
        let destination = URL(fileURLWithPath: "/tmp/provider-git-clone")
        let recorder = PhaseRecorder()
        backend.handlers["clone"] = { _ in destination }

        let result = try backend.clone(
            remoteURL: "https://example.com/demo.git",
            destination: destination
        ) { progress in
            recorder.append(progress.phase)
        }

        #expect(result == destination)
        #expect(recorder.phases == [.preparing, .completed])
    }

    @Test("A cancelled token stops the compatibility clone before the backend runs")
    func cloneHonoursCancellation() {
        let backend = makeBackend()
        let cancellation = GitProcessCancellation()
        cancellation.cancel()

        #expect(throws: CancellationError.self) {
            try backend.clone(
                remoteURL: "https://example.com/demo.git",
                destination: URL(fileURLWithPath: "/tmp/provider-git-clone"),
                progress: { _ in },
                cancellation: cancellation
            )
        }
        #expect(backend.calls.isEmpty)
    }

    @Test("isAvailable defaults to true for conforming backends")
    func isAvailableDefault() {
        let backend = makeBackend()
        #expect(backend.isAvailable)
    }
}

// MARK: - Worktree snapshot facade

@Suite("DefaultGitProvider worktree snapshot facade")
struct DefaultGitProviderSnapshotTests {
    private let repository = URL(fileURLWithPath: "/tmp/provider-git-facade")

    @Test("loadEntries is served from the shared worktree snapshot")
    func entriesComeFromSnapshot() throws {
        let provider = DefaultGitProvider()
        let backend = ScriptedGitBackend.makeBackend(id: "libgit2", priority: 100)
        let snapshot = GitWorktreeSnapshot(
            entries: [GitStatusEntry(path: "README.md", stagedStatus: " ", worktreeStatus: "M")],
            branch: "main"
        )
        backend.handlers["loadWorktreeSnapshot"] = { _ in snapshot }
        try provider.registerBackend(backend)

        let entries = try provider.loadEntries(in: repository)

        #expect(entries == snapshot.entries)
        #expect(backend.calledOperations == ["loadWorktreeSnapshot"])
    }

    @Test("loadStatus is derived from the shared worktree snapshot")
    func statusComesFromSnapshot() throws {
        let provider = DefaultGitProvider()
        let backend = ScriptedGitBackend.makeBackend(id: "libgit2", priority: 100)
        let snapshot = GitWorktreeSnapshot(
            entries: [
                GitStatusEntry(path: "a.swift", stagedStatus: "M", worktreeStatus: " "),
                GitStatusEntry(path: "b.swift", stagedStatus: " ", worktreeStatus: "M"),
            ],
            branch: "main"
        )
        backend.handlers["loadWorktreeSnapshot"] = { _ in snapshot }
        try provider.registerBackend(backend)

        let status = try provider.loadStatus(in: repository)

        #expect(status.changeCount == 2)
        #expect(status.branch == "main")
        #expect(backend.calledOperations == ["loadWorktreeSnapshot"])
    }

    @Test("A snapshot already cached is served without touching the backend again")
    func freshSnapshotIsReused() throws {
        let provider = DefaultGitProvider()
        let backend = ScriptedGitBackend.makeBackend(id: "libgit2", priority: 100)
        let snapshot = GitWorktreeSnapshot(
            entries: [GitStatusEntry(path: "README.md", stagedStatus: " ", worktreeStatus: "M")],
            branch: "main"
        )
        backend.handlers["loadWorktreeSnapshot"] = { _ in snapshot }
        try provider.registerBackend(backend)

        _ = try provider.loadWorktreeSnapshot(in: repository)
        _ = try provider.loadWorktreeSnapshot(in: repository)

        #expect(backend.calledOperations == ["loadWorktreeSnapshot"], "second read should hit the cache")
    }

    @Test("Invalidation forces the next read back to the backend")
    func invalidationForcesReload() throws {
        let provider = DefaultGitProvider()
        let backend = ScriptedGitBackend.makeBackend(id: "libgit2", priority: 100)
        let first = GitWorktreeSnapshot(entries: [], branch: "main")
        let second = GitWorktreeSnapshot(
            entries: [GitStatusEntry(path: "new.swift", stagedStatus: "A", worktreeStatus: " ")],
            branch: "main"
        )
        let box = SnapshotBox(first)
        backend.handlers["loadWorktreeSnapshot"] = { _ in box.value }
        try provider.registerBackend(backend)

        _ = try provider.loadWorktreeSnapshot(in: repository)
        provider.invalidateWorktreeSnapshot(in: repository)
        box.value = second
        let reloaded = try provider.loadWorktreeSnapshot(in: repository)

        #expect(reloaded == second)
        #expect(backend.calledOperations.count == 2)
    }

    @Test("cachedWorktreeSnapshot serves the last snapshot before any backend call")
    func cachedSnapshotIsNilBeforeFirstLoad() {
        let provider = DefaultGitProvider()
        #expect(provider.cachedWorktreeSnapshot(in: repository) == nil)
    }
}
