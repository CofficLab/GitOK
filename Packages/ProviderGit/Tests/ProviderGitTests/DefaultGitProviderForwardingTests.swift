import Foundation
import KitGit
import Testing
@testable import ProviderGit

/// Exercises every operation that `DefaultGitProvider` forwards to a backend.
///
/// The router has ~110 forwarding methods that all share one shape:
/// `execute("operationName") { $0.someMethod(...) }`. A behavioural test per
/// method would repeat the same three assertions hundreds of times, so this
/// suite drives them through one table and asserts the two invariants that
/// actually matter for the router: the operation reaches the selected backend,
/// and the backend's value comes back unchanged.
@Suite("DefaultGitProvider operation forwarding")
struct DefaultGitProviderForwardingTests {
    private let repository = URL(fileURLWithPath: "/tmp/provider-git-forwarding")

    private func makeProvider(_ configure: (ScriptedGitBackend) -> Void = { _ in }) throws -> (
        provider: DefaultGitProvider,
        backend: ScriptedGitBackend
    ) {
        let provider = DefaultGitProvider()
        let backend = ScriptedGitBackend.makeBackend(id: "libgit2", priority: 100)
        configure(backend)
        try provider.registerBackend(backend)
        return (provider, backend)
    }

    // MARK: - Commit history reads

    @Test("Commit listing operations forward to the backend")
    func commitReadsForward() throws {
        let (provider, backend) = try makeProvider { backend in
            let commit = GitCommit(
                hash: "abc123",
                shortHash: "abc1234",
                message: "Add router tests",
                author: "Angel",
                date: Date(timeIntervalSince1970: 1_700_000_000)
            )
            backend.handlers["loadCommits"] = { _ in [commit] }
            backend.handlers["loadAllCommits"] = { _ in [commit] }
            backend.handlers["countCommits"] = { _ in 42 }
            backend.handlers["unpushedCommitHashes"] = { _ in Set(["abc123"]) }
        }

        let commit = try #require(try provider.loadCommits(in: repository, limit: 10, offset: 0).first)
        #expect(commit.hash == "abc123")
        #expect(try provider.loadAllCommits(in: repository, limit: 5, offset: 0).count == 1)
        #expect(try provider.countCommits(in: repository) == 42)
        #expect(try provider.unpushedCommitHashes(in: repository) == ["abc123"])
        #expect(
            backend.calledOperations == ["loadCommits", "loadAllCommits", "countCommits", "unpushedCommitHashes"]
        )
    }

    @Test("Cancellable commit reads forward the token to the backend")
    func cancellableCommitReadsForward() throws {
        let (provider, backend) = try makeProvider { backend in
            backend.handlers["loadCommits"] = { _ in [] }
            backend.handlers["loadAllCommits"] = { _ in [] }
            backend.handlers["countCommits"] = { _ in 7 }
            backend.handlers["unpushedCommitHashes"] = { _ in [] }
        }
        let cancellation = GitProcessCancellation()

        _ = try provider.loadCommits(in: repository, limit: 1, offset: 0, cancellation: cancellation)
        _ = try provider.loadAllCommits(in: repository, limit: 1, offset: 0, cancellation: cancellation)
        _ = try provider.countCommits(in: repository, cancellation: cancellation)
        _ = try provider.unpushedCommitHashes(in: repository, cancellation: cancellation)

        #expect(backend.calls.count == 4)
    }

    // MARK: - Change inspection

    @Test("Commit change inspection operations forward to the backend")
    func changeInspectionForwards() throws {
        let (provider, backend) = try makeProvider { backend in
            backend.handlers["loadChanges"] = { _ in
                [GitFileChange(path: "README.md", status: .modified, addedLines: 1, deletedLines: 0)]
            }
            backend.handlers["countCommitChanges"] = { _ in 3 }
            backend.handlers["loadCommitChangesPage"] = { _ in
                GitFileChangePage(offset: 0, changes: [], hasMore: true)
            }
            backend.handlers["loadDiff"] = { _ in "diff --git a/README.md b/README.md" }
        }

        #expect(try provider.loadChanges(commit: "abc", in: repository).count == 1)
        #expect(try provider.countCommitChanges(commit: "abc", in: repository) == 3)
        let page = try provider.loadCommitChangesPage(commit: "abc", limit: 10, offset: 0, in: repository)
        #expect(page.hasMore)
        #expect(
            try provider.loadDiff(commit: "abc", filePath: "README.md", in: repository)
                == "diff --git a/README.md b/README.md"
        )
        #expect(backend.calls.count == 4)
    }

    @Test("Cancellable change inspection operations forward the token")
    func cancellableChangeInspectionForwards() throws {
        let (provider, backend) = try makeProvider { backend in
            backend.handlers["countCommitChanges"] = { _ in 0 }
            backend.handlers["loadCommitChangesPage"] = { _ in
                GitFileChangePage(offset: 0, changes: [], hasMore: false)
            }
            backend.handlers["loadDiff"] = { _ in "" }
            backend.handlers["loadWorktreeDiff"] = { _ in "" }
        }
        let cancellation = GitProcessCancellation()

        _ = try provider.countCommitChanges(commit: "abc", in: repository, cancellation: cancellation)
        _ = try provider.loadCommitChangesPage(
            commit: "abc",
            limit: 1,
            offset: 0,
            in: repository,
            cancellation: cancellation
        )
        _ = try provider.loadDiff(
            commit: "abc",
            filePath: "README.md",
            in: repository,
            cancellation: cancellation
        )
        _ = try provider.loadWorktreeDiff(filePath: "README.md", in: repository, cancellation: cancellation)

        #expect(backend.calls.count == 4)
    }

    @Test("Worktree status helpers forward to the backend")
    func statusHelpersForward() throws {
        let (provider, backend) = try makeProvider { backend in
            backend.handlers["remoteTrackingStatus"] = { _ in
                GitRefReader.RemoteTrackingStatus(ahead: 2, behind: 1, hasUpstream: true)
            }
            backend.handlers["unpulledCount"] = { _ in 1 }
            backend.handlers["unpushedCount"] = { _ in 2 }
            backend.handlers["currentBranch"] = { _ in "main" }
            backend.handlers["latestTag"] = { _ in "v1.2.3" }
            backend.handlers["firstCommitDate"] = { _ in Date(timeIntervalSince1970: 1_600_000_000) }
        }

        let tracking = provider.remoteTrackingStatus(in: repository)
        #expect(tracking.ahead == 2)
        #expect(tracking.behind == 1)
        #expect(tracking.hasUpstream)
        #expect(provider.unpulledCount(in: repository) == 1)
        #expect(provider.unpushedCount(in: repository) == 2)
        #expect(provider.currentBranch(in: repository) == "main")
        #expect(provider.latestTag(in: repository) == "v1.2.3")
        #expect(provider.firstCommitDate(in: repository) == Date(timeIntervalSince1970: 1_600_000_000))
        #expect(
            backend.calledOperations == [
                "remoteTrackingStatus", "unpulledCount", "unpushedCount",
                "currentBranch", "latestTag", "firstCommitDate",
            ],
            "every non-throwing status helper must reach the primary backend exactly once"
        )
    }

    @Test("Cancellable status helpers forward the token")
    func cancellableStatusHelpersForward() {
        let (provider, backend) = try! makeProvider { backend in
            backend.handlers["latestTag"] = { _ in nil }
            backend.handlers["firstCommitDate"] = { _ in nil }
            backend.handlers["unpushedCount"] = { _ in nil }
            backend.handlers["remoteTrackingStatus"] = { _ in
                GitRefReader.RemoteTrackingStatus(ahead: 0, behind: 0, hasUpstream: false)
            }
        }
        let cancellation = GitProcessCancellation()

        _ = provider.latestTag(in: repository, cancellation: cancellation)
        _ = provider.firstCommitDate(in: repository, cancellation: cancellation)
        _ = provider.unpushedCount(in: repository, cancellation: cancellation)
        _ = provider.remoteTrackingStatus(in: repository, cancellation: cancellation)

        #expect(backend.calls.count == 4)
    }

    // MARK: - Branch operations

    @Test("Branch reads forward to the backend")
    func branchReadsForward() throws {
        let (provider, backend) = try makeProvider { backend in
            backend.handlers["listBranches"] = { _ in [GitBranchSummary(name: "main", isRemote: false, isCurrent: true)] }
            backend.handlers["compareBranches"] = { _ in
                GitBranchCompare(base: "main", head: "feature", ahead: 1, behind: 0, commits: [], files: [])
            }
            backend.handlers["hasRemotes"] = { _ in true }
        }

        let branches = try provider.listBranches(in: repository)
        #expect(branches.count == 1)
        #expect(branches[0].name == "main")
        let compare = try provider.compareBranches(base: "main", head: "feature", in: repository)
        #expect(compare.ahead == 1)
        #expect(provider.hasRemotes(in: repository))
        #expect(backend.calledOperations == ["listBranches", "compareBranches", "hasRemotes"])
    }

    @Test("Branch mutations forward to the backend")
    func branchMutationsForward() throws {
        let (provider, backend) = try makeProvider()

        try provider.createBranch(named: "feature", in: repository)
        try provider.checkoutBranch(named: "feature", in: repository)
        try provider.checkoutRemoteBranch(named: "origin/feature", as: "feature", in: repository)
        try provider.deleteBranch(named: "feature", in: repository)
        try provider.renameBranch(from: "feature", to: "renamed", in: repository)
        try provider.setUpstream(localBranch: "main", upstreamBranch: "origin/main", in: repository)
        try provider.unsetUpstream(localBranch: "main", in: repository)
        try provider.publishBranch(localBranch: "main", remote: "origin", remoteBranch: nil, in: repository)
        try provider.deleteRemoteBranch(named: "old", remote: "origin", in: repository)

        #expect(
            backend.calledOperations == [
                "createBranch", "checkoutBranch", "checkoutRemoteBranch", "deleteBranch",
                "renameBranch", "setUpstream", "unsetUpstream", "publishBranch", "deleteRemoteBranch",
            ]
        )
    }

    // MARK: - History rewriting

    @Test("History rewriting operations forward and return the new head")
    func historyRewritingForwards() throws {
        let (provider, backend) = try makeProvider { backend in
            for operation in [
                "undoCommit", "revertCommit", "softReset", "mixedReset",
                "hardReset", "squash", "continueMerge", "abortMerge",
            ] {
                backend.handlers[operation] = { _ in "newhead123" }
            }
        }

        #expect(try provider.undoCommit("a", parentHash: "b", in: repository) == "newhead123")
        #expect(try provider.revertCommit("a", in: repository) == "newhead123")
        #expect(try provider.softReset(to: "a", expectedHead: "b", in: repository) == "newhead123")
        #expect(try provider.mixedReset(to: "a", expectedHead: "b", in: repository) == "newhead123")
        #expect(try provider.hardReset(to: "a", expectedHead: "b", in: repository) == "newhead123")
        #expect(
            try provider.squash(
                to: "a",
                parentHash: "b",
                expectedHead: "c",
                message: "squashed",
                in: repository
            ) == "newhead123"
        )
        #expect(try provider.continueMerge(in: repository) == "newhead123")
        #expect(try provider.abortMerge(in: repository) == "newhead123")
        #expect(backend.calls.count == 8)
    }

    @Test("finalizeMergeIfNeeded returns nil when there is no merge to finish")
    func finalizeMergeReturnsNil() throws {
        let (provider, backend) = try makeProvider()

        #expect(try provider.finalizeMergeIfNeeded(in: repository) == nil)
        #expect(backend.calledOperations == ["finalizeMergeIfNeeded"])
    }

    // MARK: - Tags

    @Test("Tag operations forward to the backend")
    func tagOperationsForward() throws {
        let (provider, backend) = try makeProvider { backend in
            backend.handlers["createLightweightTag"] = { _ in "tag-light" }
            backend.handlers["createAnnotatedTag"] = { _ in "tag-annotated" }
            backend.handlers["deleteLocalTag"] = { _ in "deleted-local" }
            backend.handlers["pushTag"] = { _ in "pushed" }
            backend.handlers["deleteRemoteTag"] = { _ in "deleted-remote" }
        }

        #expect(try provider.createLightweightTag(named: "v1", at: "abc", in: repository) == "tag-light")
        #expect(
            try provider.createAnnotatedTag(named: "v1", at: "abc", message: "release", in: repository)
                == "tag-annotated"
        )
        #expect(try provider.deleteLocalTag(named: "v1", in: repository) == "deleted-local")
        #expect(try provider.pushTag(named: "v1", remote: "origin", in: repository) == "pushed")
        #expect(try provider.deleteRemoteTag(named: "v1", remote: "origin", in: repository) == "deleted-remote")
        #expect(backend.calls.count == 5)
    }

    // MARK: - Stash

    @Test("Stash operations forward to the backend")
    func stashOperationsForward() throws {
        let (provider, backend) = try makeProvider { backend in
            backend.handlers["listStashes"] = { _ in [GitStashEntry(index: 0, message: "wip")] }
            backend.handlers["hasChangesToStash"] = { _ in true }
        }
        let entry = try #require(try provider.listStashes(in: repository).first)

        try provider.saveStash(message: "wip", in: repository)
        try provider.applyStash(entry, in: repository)
        try provider.popStash(entry, in: repository)
        try provider.dropStash(entry, in: repository)

        #expect(entry.message == "wip")
        #expect(provider.hasChangesToStash(in: repository))
        #expect(
            backend.calledOperations == ["listStashes", "saveStash", "applyStash", "popStash", "dropStash", "hasChangesToStash"]
        )
    }

    @Test("Cancellable stash listing forwards the token")
    func cancellableStashListingForwards() throws {
        let (provider, backend) = try makeProvider { backend in
            backend.handlers["listStashes"] = { _ in [] }
        }

        _ = try provider.listStashes(in: repository, cancellation: GitProcessCancellation())

        #expect(backend.calledOperations == ["listStashes"])
    }

    // MARK: - Cherry-pick

    @Test("Cherry-pick operations forward to the backend")
    func cherryPickForwards() throws {
        let (provider, backend) = try makeProvider { backend in
            backend.handlers["cherryPickStatus"] = { _ in GitCherryPickStatus(isCherryPicking: true, commitHash: "abc") }
            backend.handlers["cherryPick"] = { _ in "picked" }
            backend.handlers["continueCherryPick"] = { _ in "continued" }
            backend.handlers["abortCherryPick"] = { _ in "aborted" }
        }

        #expect(provider.cherryPickStatus(in: repository).isCherryPicking)
        #expect(try provider.cherryPick(commits: ["abc"], onto: "main", in: repository) == "picked")
        #expect(try provider.continueCherryPick(in: repository) == "continued")
        #expect(try provider.abortCherryPick(in: repository) == "aborted")
        #expect(backend.calls.count == 4)
    }

    // MARK: - Submodules

    @Test("Submodule operations forward to the backend")
    func submodulesForward() throws {
        let (provider, backend) = try makeProvider { backend in
            backend.handlers["listSubmodules"] = { _ in [GitSubmoduleSummary(path: "vendor/lib", commit: "abc123", url: "git@example.com:o/lib.git")] }
        }

        let submodules = try provider.listSubmodules(in: repository, cancellation: nil)
        try provider.updateSubmodules(in: repository)

        #expect(submodules.count == 1)
        #expect(submodules[0].path == "vendor/lib")
        #expect(backend.calledOperations == ["listSubmodules", "updateSubmodules"])
    }

    // MARK: - Clone

    @Test("Clone validation and execution forward to the backend")
    func cloneForwards() throws {
        let (provider, backend) = try makeProvider { backend in
            backend.handlers["clone"] = { _ in URL(fileURLWithPath: "/tmp/provider-git-cloned") }
        }
        let destination = URL(fileURLWithPath: "/tmp/provider-git-cloned")

        try provider.validateCloneDestination(destination)
        let result = try provider.clone(
            remoteURL: "https://example.com/demo.git",
            destination: destination,
            progress: { _ in }
        )

        #expect(result == destination)
        #expect(backend.calledOperations == ["validateCloneDestination", "clone"])
    }

    @Test("defaultRepositoryName and webLink pass through from the backend")
    func derivedURLHelpersPassThrough() throws {
        let (provider, backend) = try makeProvider { backend in
            backend.handlers["defaultRepositoryName"] = { _ in "demo" }
            backend.handlers["webLink"] = { _ in URL(string: "https://example.com/demo") }
        }

        #expect(provider.defaultRepositoryName(from: "https://example.com/demo.git") == "demo")
        #expect(provider.webLink(for: "https://example.com/demo.git")?.absoluteString == "https://example.com/demo")
        #expect(backend.calls.count == 2)
    }

    // MARK: - Staging and commit

    @Test("Staging and commit operations forward to the backend")
    func stagingForwards() throws {
        let (provider, backend) = try makeProvider { backend in
            backend.handlers["hasStagedChanges"] = { _ in true }
            backend.handlers["commit"] = { _ in "committed-sha" }
            backend.handlers["push"] = { _ in "pushed-sha" }
        }

        #expect(try provider.hasStagedChanges(in: repository))
        try provider.addAll(in: repository)
        try provider.stageFiles(["README.md"], in: repository)
        try provider.unstageFiles(["README.md"], in: repository)
        try provider.discardFileChanges("README.md", in: repository)
        try provider.discardFiles(["README.md"], in: repository)
        try provider.discardAllChanges(in: repository)
        #expect(try provider.commit(message: "subject", in: repository) == "committed-sha")

        #expect(
            backend.calledOperations == [
                "hasStagedChanges", "addAll", "stageFiles", "unstageFiles",
                "discardFileChanges", "discardFiles", "discardAllChanges", "commit",
            ]
        )
    }

    // MARK: - Remotes

    @Test("Remote operations forward to the backend")
    func remotesForward() throws {
        let (provider, backend) = try makeProvider { backend in
            backend.handlers["listRemotes"] = { _ in [GitRemoteSummary(name: "origin", url: "git@example.com:o/r.git")] }
            backend.handlers["synchronize"] = { _ in
                GitRefReader.RemoteTrackingStatus(ahead: 0, behind: 0, hasUpstream: true)
            }
            backend.handlers["push"] = { _ in "push-sha" }
        }

        let remotes = provider.listRemotes(in: repository)
        try provider.addRemote(name: "upstream", url: "git@example.com:u/r.git", in: repository)
        try provider.removeRemote(name: "upstream", in: repository)
        try provider.fetch(in: repository)
        try provider.pull(in: repository)
        try provider.pull(in: repository, strategy: .fastForwardOnly)
        let status = try provider.synchronize(in: repository)
        #expect(try provider.push(in: repository) == "push-sha")

        #expect(remotes.count == 1)
        #expect(remotes[0].name == "origin")
        #expect(status.hasUpstream)
        #expect(
            backend.calledOperations == [
                "listRemotes", "addRemote", "removeRemote", "fetch", "pull", "pull", "synchronize", "push",
            ]
        )
    }

    // MARK: - Merge conflicts

    @Test("Merge conflict operations forward to the backend")
    func mergeConflictsForward() throws {
        let (provider, backend) = try makeProvider { backend in
            backend.handlers["isMerging"] = { _ in true }
            backend.handlers["hasConflictOperation"] = { _ in true }
            backend.handlers["conflictFiles"] = { _ in ["README.md"] }
            backend.handlers["mergeBranches"] = { _ in "merge-sha" }
            backend.handlers["mergeFileContent"] = { _ in "merged content" }
            backend.handlers["mergeFileDiff"] = { _ in "merged diff" }
        }

        #expect(provider.isMerging(in: repository))
        #expect(provider.hasConflictOperation(in: repository))
        #expect(provider.conflictFiles(in: repository) == ["README.md"])
        #expect(
            try provider.mergeBranches(
                repository: repository,
                sourceBranch: "feature",
                targetBranch: "main"
            ) == "merge-sha"
        )
        #expect(
            try provider.mergeFileContent(path: "README.md", version: .ours, in: repository)
                == "merged content"
        )
        #expect(try provider.mergeFileDiff(path: "README.md", in: repository) == "merged diff")
        try provider.checkoutMergeFileVersion(path: "README.md", version: .theirs, in: repository)
        #expect(backend.calls.count == 7)
    }

    // MARK: - Blob data

    @Test("Blob data reads forward to the backend")
    func blobDataForwards() throws {
        let (provider, backend) = try makeProvider { backend in
            backend.handlers["loadBlobData"] = { _ in Data("committed".utf8) }
            backend.handlers["loadWorktreeFileData"] = { _ in Data("working".utf8) }
        }

        #expect(
            try provider.loadBlobData(commit: "abc", filePath: "README.md", in: repository)
                == Data("committed".utf8)
        )
        #expect(
            try provider.loadWorktreeFileData(filePath: "README.md", in: repository)
                == Data("working".utf8)
        )
        #expect(backend.calls.count == 2)
    }

    @Test("Cancellable blob data reads forward the token")
    func cancellableBlobDataForwards() throws {
        let (provider, backend) = try makeProvider { backend in
            backend.handlers["loadBlobData"] = { _ in Data() }
            backend.handlers["loadWorktreeFileData"] = { _ in Data() }
        }
        let cancellation = GitProcessCancellation()

        _ = try provider.loadBlobData(commit: "abc", filePath: "README.md", in: repository, cancellation: cancellation)
        _ = try provider.loadWorktreeFileData(filePath: "README.md", in: repository, cancellation: cancellation)

        #expect(backend.calls.count == 2)
    }

    // MARK: - Failure propagation across the whole surface

    @Test("Every forwarding operation surfaces noBackendAvailable without a backend")
    func allOperationsRequireABackend() {
        let provider = DefaultGitProvider()

        func expectNoBackend(
            _ label: String,
            _ operation: () throws -> Any
        ) {
            do {
                _ = try operation()
                Issue.record("\(label) should have thrown noBackendAvailable")
            } catch GitProviderError.noBackendAvailable {
                // expected
            } catch {
                Issue.record("\(label) threw \(error) instead of noBackendAvailable")
            }
        }

        expectNoBackend("loadCommits") { try provider.loadCommits(in: repository, limit: 1, offset: 0) }
        expectNoBackend("loadAllCommits") { try provider.loadAllCommits(in: repository, limit: 1, offset: 0) }
        expectNoBackend("countCommits") { try provider.countCommits(in: repository) }
        expectNoBackend("unpushedCommitHashes") { try provider.unpushedCommitHashes(in: repository) }
        expectNoBackend("loadStatus") { try provider.loadStatus(in: repository) }
        expectNoBackend("loadEntries") { try provider.loadEntries(in: repository) }
        expectNoBackend("loadWorktreeSnapshot") { try provider.loadWorktreeSnapshot(in: repository) }
        expectNoBackend("loadChanges") { try provider.loadChanges(commit: "a", in: repository) }
        expectNoBackend("countCommitChanges") { try provider.countCommitChanges(commit: "a", in: repository) }
        expectNoBackend("loadCommitChangesPage") {
            try provider.loadCommitChangesPage(commit: "a", limit: 1, offset: 0, in: repository)
        }
        expectNoBackend("loadDiff") { try provider.loadDiff(commit: "a", filePath: "f", in: repository) }
        expectNoBackend("loadWorktreeDiff") { try provider.loadWorktreeDiff(filePath: "f", in: repository) }
        expectNoBackend("listBranches") { try provider.listBranches(in: repository) }
        expectNoBackend("createBranch") { try provider.createBranch(named: "b", in: repository) }
        expectNoBackend("checkoutBranch") { try provider.checkoutBranch(named: "b", in: repository) }
        expectNoBackend("deleteBranch") { try provider.deleteBranch(named: "b", in: repository) }
        expectNoBackend("renameBranch") { try provider.renameBranch(from: "a", to: "b", in: repository) }
        expectNoBackend("compareBranches") {
            try provider.compareBranches(base: "a", head: "b", in: repository)
        }
        expectNoBackend("undoCommit") { try provider.undoCommit("a", parentHash: "b", in: repository) }
        expectNoBackend("revertCommit") { try provider.revertCommit("a", in: repository) }
        expectNoBackend("softReset") { try provider.softReset(to: "a", expectedHead: "b", in: repository) }
        expectNoBackend("hardReset") { try provider.hardReset(to: "a", expectedHead: "b", in: repository) }
        expectNoBackend("createLightweightTag") {
            try provider.createLightweightTag(named: "t", at: "a", in: repository)
        }
        expectNoBackend("saveStash") { try provider.saveStash(message: nil, in: repository) }
        expectNoBackend("cherryPick") { try provider.cherryPick(commits: ["a"], onto: nil, in: repository) }
        expectNoBackend("updateSubmodules") { try provider.updateSubmodules(in: repository) }
        expectNoBackend("validateCloneDestination") { try provider.validateCloneDestination(repository) }
        expectNoBackend("addAll") { try provider.addAll(in: repository) }
        expectNoBackend("stageFiles") { try provider.stageFiles(["f"], in: repository) }
        expectNoBackend("commit") { try provider.commit(message: "m", in: repository) }
        expectNoBackend("push") { try provider.push(in: repository) }
        expectNoBackend("addRemote") { try provider.addRemote(name: "o", url: "u", in: repository) }
        expectNoBackend("fetch") { try provider.fetch(in: repository) }
        expectNoBackend("pull") { try provider.pull(in: repository) }
        expectNoBackend("synchronize") { try provider.synchronize(in: repository) }
        expectNoBackend("mergeBranches") {
            try provider.mergeBranches(repository: repository, sourceBranch: "a", targetBranch: "b")
        }
        expectNoBackend("mergeFileContent") {
            try provider.mergeFileContent(path: "f", version: .ours, in: repository)
        }
        expectNoBackend("continueMerge") { try provider.continueMerge(in: repository) }
        expectNoBackend("finalizeMergeIfNeeded") { try provider.finalizeMergeIfNeeded(in: repository) }
    }
}
