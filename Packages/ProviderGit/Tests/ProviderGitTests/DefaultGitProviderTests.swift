import Foundation
import KitGit
import Testing
@testable import ProviderGit

// MARK: - Backend registry

@Suite("DefaultGitProvider backend registry")
struct DefaultGitProviderRegistryTests {
    private let repository = URL(fileURLWithPath: "/tmp/provider-git-router")

    @Test("No backend registered surfaces noBackendAvailable")
    func noBackendRegistered() {
        let provider = DefaultGitProvider()

        #expect(provider.availableBackends.isEmpty)
        #expect(throws: GitProviderError.noBackendAvailable) {
            try provider.loadCommits(in: repository, limit: 10, offset: 0)
        }
    }

    @Test("An unavailable backend is skipped entirely")
    func unavailableBackendIsSkipped() throws {
        let provider = DefaultGitProvider()
        let offline = ScriptedGitBackend.makeBackend(id: "offline", priority: 900, isAvailable: false)
        try provider.registerBackend(offline)

        #expect(provider.availableBackends.isEmpty)
        #expect(throws: GitProviderError.noBackendAvailable) {
            try provider.fetch(in: repository)
        }
        #expect(offline.calls.isEmpty, "an unavailable backend must not be invoked")
    }

    @Test("Registering the same backend id twice is rejected")
    func duplicateRegistrationRejected() throws {
        let provider = DefaultGitProvider()
        try provider.registerBackend(ScriptedGitBackend.makeBackend(id: "libgit2", priority: 100))

        #expect(throws: GitProviderError.backendAlreadyRegistered("libgit2")) {
            try provider.registerBackend(ScriptedGitBackend.makeBackend(id: "libgit2", priority: 100))
        }
        #expect(provider.availableBackends.count == 1)
    }

    @Test("availableBackends orders by priority then id")
    func availableBackendsOrdering() throws {
        let provider = DefaultGitProvider()
        try provider.registerBackend(ScriptedGitBackend.makeBackend(id: "low", priority: 10))
        try provider.registerBackend(ScriptedGitBackend.makeBackend(id: "zeta", priority: 100))
        try provider.registerBackend(ScriptedGitBackend.makeBackend(id: "alpha", priority: 100))
        try provider.registerBackend(ScriptedGitBackend.makeBackend(id: "hidden", priority: 999, isAvailable: false))

        #expect(provider.availableBackends.map(\.id) == ["alpha", "zeta", "low"])
    }

    @Test("unregisterBackend removes the backend from routing")
    func unregisterRemovesBackend() throws {
        let provider = DefaultGitProvider()
        try provider.registerBackend(ScriptedGitBackend.makeBackend(id: "libgit2", priority: 100))

        provider.unregisterBackend(id: "libgit2")

        #expect(provider.availableBackends.isEmpty)
        #expect(throws: GitProviderError.noBackendAvailable) {
            try provider.listBranches(in: repository)
        }
    }

    @Test("unregistering an unknown id is a no-op")
    func unregisterUnknownIsNoop() throws {
        let provider = DefaultGitProvider()
        try provider.registerBackend(ScriptedGitBackend.makeBackend(id: "libgit2", priority: 100))

        provider.unregisterBackend(id: "never-registered")

        #expect(provider.availableBackends.map(\.id) == ["libgit2"])
    }
}

// MARK: - Backend selection and failover

@Suite("DefaultGitProvider backend routing")
struct DefaultGitProviderRoutingTests {
    private let repository = URL(fileURLWithPath: "/tmp/provider-git-routing")

    @Test("The highest-priority backend handles the operation")
    func highestPriorityBackendWins() throws {
        let provider = DefaultGitProvider()
        let preferred = ScriptedGitBackend.makeBackend(id: "preferred", priority: 100)
        let fallback = ScriptedGitBackend.makeBackend(id: "fallback", priority: 10)
        try provider.registerBackend(preferred)
        try provider.registerBackend(fallback)

        _ = try provider.listBranches(in: repository)

        #expect(preferred.calledOperations == ["listBranches"])
        #expect(fallback.calls.isEmpty)
    }

    @Test("An unsupported operation falls through to the next backend")
    func unsupportedFallsThroughToNextBackend() throws {
        let provider = DefaultGitProvider()
        let preferred = ScriptedGitBackend.makeBackend(id: "preferred", priority: 100)
        let fallback = ScriptedGitBackend.makeBackend(id: "fallback", priority: 10)
        preferred.handlers["listBranches"] = { _ in
            throw GitProviderError.backendOperationUnsupported("libgit2 has no branch listing")
        }
        try provider.registerBackend(preferred)
        try provider.registerBackend(fallback)

        _ = try provider.listBranches(in: repository)

        #expect(preferred.calledOperations == ["listBranches"])
        #expect(fallback.calledOperations == ["listBranches"])
    }

    @Test("allBackendsFailed aggregates every unsupported failure in priority order")
    func allBackendsUnsupportedAggregatesFailures() throws {
        let provider = DefaultGitProvider()
        let first = ScriptedGitBackend.makeBackend(id: "first", priority: 100, name: "First Backend")
        let second = ScriptedGitBackend.makeBackend(id: "second", priority: 50, name: "Second Backend")
        first.handlers["countCommits"] = { _ in
            throw GitProviderError.backendOperationUnsupported("first lacks counting")
        }
        second.handlers["countCommits"] = { _ in
            throw GitProviderError.backendOperationUnsupported("second lacks counting")
        }
        try provider.registerBackend(first)
        try provider.registerBackend(second)

        let error = #expect(throws: GitProviderError.self) {
            try provider.countCommits(in: repository)
        }

        guard case .allBackendsFailed(let operation, let failures) = try #require(error) else {
            Issue.record("expected allBackendsFailed, got \(String(describing: error))")
            return
        }
        #expect(operation == "countCommits")
        #expect(failures.count == 2)
        #expect(failures[0].backendID == "first")
        #expect(failures[0].backendName == "First Backend")
        #expect(failures[0].message == "first lacks counting")
        #expect(failures[1].backendID == "second")
        #expect(failures[1].message == "second lacks counting")
    }

    @Test("A hard failure is not retried on another backend")
    func hardFailureIsNotRetried() throws {
        let provider = DefaultGitProvider()
        struct WriteError: Error, Equatable { let reason: String }
        let preferred = ScriptedGitBackend.makeBackend(id: "preferred", priority: 100)
        let fallback = ScriptedGitBackend.makeBackend(id: "fallback", priority: 10)
        preferred.handlers["commit"] = { _ in throw WriteError(reason: "pre-receive hook rejected") }
        try provider.registerBackend(preferred)
        try provider.registerBackend(fallback)

        let error = #expect(throws: WriteError.self) {
            try provider.commit(message: "subject", in: repository)
        }
        #expect(error?.reason == "pre-receive hook rejected")
        #expect(
            fallback.calls.isEmpty,
            "a write that may already have taken effect must not be replayed on another backend"
        )
    }

    @Test("Unavailable backends are never asked to handle an operation")
    func unavailableBackendsNotConsulted() throws {
        let provider = DefaultGitProvider()
        let offline = ScriptedGitBackend.makeBackend(id: "offline", priority: 900, isAvailable: false)
        let online = ScriptedGitBackend.makeBackend(id: "online", priority: 100)
        try provider.registerBackend(offline)
        try provider.registerBackend(online)

        _ = try provider.currentBranch(in: repository)

        #expect(online.calledOperations == ["currentBranch"])
        #expect(offline.calls.isEmpty)
    }

    @Test("A single available backend that reports unsupported still surfaces a typed error")
    func singleUnsupportedBackendSurfacesTypedError() throws {
        let provider = DefaultGitProvider()
        let only = ScriptedGitBackend.makeBackend(id: "only", priority: 1)
        only.handlers["mergeFileDiff"] = { _ in
            throw GitProviderError.backendOperationUnsupported("diff generation unavailable")
        }
        try provider.registerBackend(only)

        let error = #expect(throws: GitProviderError.self) {
            try provider.mergeFileDiff(path: "README.md", in: repository)
        }

        guard case .allBackendsFailed(let operation, let failures) = try #require(error) else {
            Issue.record("expected allBackendsFailed, got \(String(describing: error))")
            return
        }
        #expect(operation == "mergeFileDiff")
        #expect(failures.count == 1)
        #expect(failures[0].message == "diff generation unavailable")
    }

    @Test("Read results pass through from the selected backend unchanged")
    func readResultPassesThrough() throws {
        let provider = DefaultGitProvider()
        let backend = ScriptedGitBackend.makeBackend(id: "libgit2", priority: 100)
        let snapshot = GitWorktreeSnapshot(
            entries: [GitStatusEntry(path: "README.md", stagedStatus: " ", worktreeStatus: "M")],
            branch: "main"
        )
        backend.handlers["loadWorktreeSnapshot"] = { _ in snapshot }
        try provider.registerBackend(backend)

        #expect(try provider.loadWorktreeSnapshot(in: repository) == snapshot)
        #expect(backend.calledOperations == ["loadWorktreeSnapshot"])
    }

    @Test("Non-throwing operations route through the selected backend")
    func nonThrowingOperationsRoute() throws {
        let provider = DefaultGitProvider()
        let backend = ScriptedGitBackend.makeBackend(id: "libgit2", priority: 100)
        backend.handlers["currentBranch"] = { _ in "feature/coverage" }
        try provider.registerBackend(backend)

        #expect(provider.currentBranch(in: repository) == "feature/coverage")
        #expect(backend.calledOperations == ["currentBranch"])
    }
}
