import Foundation
import XCTest
@testable import GitCoreKit

final class GitRepositoryCLITests: XCTestCase {
    func testParseStashListOutput() {
        let output = """
        stash@{0}\u{1F}WIP on main: abc123 first stash
        stash@{1}\u{1F}custom message
        """

        XCTAssertEqual(
            GitParsers.parseStashList(output),
            [
                GitStashEntry(index: 0, message: "WIP on main: abc123 first stash"),
                GitStashEntry(index: 1, message: "custom message"),
            ]
        )
    }

    func testParseStashListNormalizesDefaultGitMessage() {
        let output = "stash@{0}\u{1F}On feature/refactor: WIP work"

        XCTAssertEqual(
            GitParsers.parseStashList(output),
            [GitStashEntry(index: 0, message: "WIP work")]
        )
    }

    func testParseStashListSkipsMalformedLinesAndKeepsEmptyMessages() {
        let output = """
        malformed
        stash@{0}\u{1F}
        stash@{x}\u{1F}bad index
        stash@{2}\u{1F}kept
        """

        XCTAssertEqual(
            GitParsers.parseStashList(output),
            [
                GitStashEntry(index: 0, message: ""),
                GitStashEntry(index: 2, message: "kept"),
            ]
        )
    }

    func testParseStatusEntriesSkipsShortLinesAndKeepsSpacesInPaths() {
        let output = """
         M README.md
        R  old name.swift -> new name.swift
        ??
        ?? folder/file with spaces.txt
        """

        XCTAssertEqual(
            GitParsers.parseStatusEntries(output),
            [
                GitStatusEntry(path: "README.md", indexStatus: " ", workTreeStatus: "M"),
                GitStatusEntry(path: "old name.swift -> new name.swift", indexStatus: "R", workTreeStatus: " "),
                GitStatusEntry(path: "folder/file with spaces.txt", indexStatus: "?", workTreeStatus: "?"),
            ]
        )
    }

    func testClassifyMergeFiles() {
        let files = GitParsers.classifyMergeFiles(
            unresolvedPaths: ["Sources/App.swift"],
            statusEntries: [
                GitStatusEntry(path: "Sources/App.swift", indexStatus: "U", workTreeStatus: "U"),
                GitStatusEntry(path: "Sources/Ready.swift", indexStatus: "M", workTreeStatus: " "),
                GitStatusEntry(path: "Sources/NeedsStage.swift", indexStatus: " ", workTreeStatus: "M"),
            ]
        )

        XCTAssertEqual(
            files,
            [
                GitMergeFile(path: "Sources/App.swift", state: .unresolved),
                GitMergeFile(path: "Sources/NeedsStage.swift", state: .pendingStage),
                GitMergeFile(path: "Sources/Ready.swift", state: .staged),
            ]
        )
    }

    func testClassifyMergeFilesSortsPathsAndMarksPendingStage() {
        let files = GitParsers.classifyMergeFiles(
            unresolvedPaths: ["b.swift"],
            statusEntries: [
                GitStatusEntry(path: "c.swift", indexStatus: "M", workTreeStatus: " "),
                GitStatusEntry(path: "a.swift", indexStatus: " ", workTreeStatus: "M"),
            ]
        )

        XCTAssertEqual(
            files,
            [
                GitMergeFile(path: "a.swift", state: .pendingStage),
                GitMergeFile(path: "b.swift", state: .unresolved),
                GitMergeFile(path: "c.swift", state: .staged),
            ]
        )
    }

    func testGitMergeFileIDUsesPath() {
        XCTAssertEqual(GitMergeFile(path: "Sources/App.swift", state: .staged).id, "Sources/App.swift")
    }

    func testParseAheadBehindCounts() {
        let counts = GitParsers.parseAheadBehindCounts("2\t3")
        XCTAssertEqual(counts?.ahead, 2)
        XCTAssertEqual(counts?.behind, 3)
        XCTAssertNil(GitParsers.parseAheadBehindCounts("not-counts"))
    }

    func testStashLifecycle() throws {
        let repo = try TestGitRepository()
        try repo.run(["commit", "--allow-empty", "-m", "initial"])

        try repo.write("notes.txt", content: "one\n")

        let client = GitRepositoryCLI(repositoryURL: repo.url)
        try client.stashSave(message: "save notes")

        let stashes = try client.stashList()
        XCTAssertEqual(stashes.count, 1)
        XCTAssertEqual(stashes[0].message, "save notes")
        XCTAssertEqual(try repo.read("notes.txt"), nil)

        try client.stashApply(index: 0)
        XCTAssertEqual(try repo.read("notes.txt"), "one\n")
        XCTAssertEqual(try client.stashList().count, 1)

        try client.stashDrop(index: 0)
        XCTAssertTrue(try client.stashList().isEmpty)
    }

    func testStashSaveWithoutWorkingTreeChangesLeavesListEmpty() throws {
        let repo = try TestGitRepository()
        try repo.run(["commit", "--allow-empty", "-m", "initial"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)

        try client.stashSave(message: "nothing to save")
        XCTAssertTrue(try client.stashList().isEmpty)
    }

    func testStashSaveCapturesUntrackedFiles() throws {
        let repo = try TestGitRepository()
        try repo.run(["commit", "--allow-empty", "-m", "initial"])

        try repo.write("draft.md", content: "hello\n")

        let client = GitRepositoryCLI(repositoryURL: repo.url)
        try client.stashSave(message: "untracked only")

        XCTAssertNil(try repo.read("draft.md"))
        XCTAssertEqual(
            try client.stashList(),
            [GitStashEntry(index: 0, message: "untracked only")]
        )

        try client.stashPop(index: 0)
        XCTAssertEqual(try repo.read("draft.md"), "hello\n")
        XCTAssertTrue(try client.stashList().isEmpty)
    }

    func testStashPopConflictKeepsEntryAndMarksConflict() throws {
        let repo = try TestGitRepository()
        try repo.write("shared.txt", content: "base\n")
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "base"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)

        try repo.write("shared.txt", content: "stash change\n")
        try client.stashSave(message: "pop conflict candidate")

        try repo.write("shared.txt", content: "head change\n")
        try repo.run(["commit", "-am", "head change"])

        XCTAssertThrowsError(try client.stashPop(index: 0))
        XCTAssertEqual(try client.stashList(), [GitStashEntry(index: 0, message: "pop conflict candidate")])
        XCTAssertEqual(
            try client.statusEntries(),
            [GitStatusEntry(path: "shared.txt", indexStatus: "U", workTreeStatus: "U")]
        )
    }

    func testStashApplyConflictKeepsEntryAndMarksConflict() throws {
        let repo = try TestGitRepository()
        try repo.write("shared.txt", content: "base\n")
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "base"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)

        try repo.write("shared.txt", content: "stash change\n")
        try client.stashSave(message: "conflict candidate")

        try repo.write("shared.txt", content: "head change\n")
        try repo.run(["commit", "-am", "head change"])

        XCTAssertThrowsError(try client.stashApply(index: 0))
        XCTAssertEqual(try client.stashList(), [GitStashEntry(index: 0, message: "conflict candidate")])
        XCTAssertEqual(try client.statusEntries(), [GitStatusEntry(path: "shared.txt", indexStatus: "U", workTreeStatus: "U")])
    }

    func testStashCommandsThrowForMissingIndex() throws {
        let repo = try TestGitRepository()
        try repo.run(["commit", "--allow-empty", "-m", "initial"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)

        XCTAssertThrowsError(try client.stashApply(index: 99))
        XCTAssertThrowsError(try client.stashPop(index: 99))
        XCTAssertThrowsError(try client.stashDrop(index: 99))
    }

    func testAheadBehindReturnsNoUpstreamForLocalOnlyBranch() throws {
        let repo = try TestGitRepository()
        try repo.run(["commit", "--allow-empty", "-m", "initial"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)

        XCTAssertEqual(try client.aheadBehind(), .noUpstream)
    }

    func testDeleteLocalBranchRemovesMergedBranch() throws {
        let repo = try TestGitRepository()
        try repo.run(["commit", "--allow-empty", "-m", "initial"])
        try repo.run(["checkout", "-b", "done"])
        try repo.run(["checkout", "master"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)
        try client.deleteLocalBranch(named: "done")

        let branches = try repo.run(["branch", "--format=%(refname:short)"])
            .split(separator: "\n")
            .map(String.init)
        XCTAssertFalse(branches.contains("done"))
    }

    func testDeleteLocalBranchRejectsCurrentBranch() throws {
        let repo = try TestGitRepository()
        try repo.run(["commit", "--allow-empty", "-m", "initial"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)

        XCTAssertThrowsError(try client.deleteLocalBranch(named: "master")) { error in
            XCTAssertTrue((error as NSError).localizedDescription.contains("不能删除当前分支"))
        }
    }

    func testCreateLightweightTagCreatesTagAtCommit() throws {
        let repo = try TestGitRepository()
        try repo.run(["commit", "--allow-empty", "-m", "initial"])
        let commitHash = try repo.run(["rev-parse", "HEAD"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)
        try client.createLightweightTag(named: "v1.0.0", commitHash: commitHash)

        XCTAssertEqual(try repo.run(["rev-parse", "v1.0.0"]), commitHash)
    }

    func testCreateLightweightTagRejectsEmptyName() throws {
        let repo = try TestGitRepository()
        try repo.run(["commit", "--allow-empty", "-m", "initial"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)

        XCTAssertThrowsError(try client.createLightweightTag(named: "  ", commitHash: "HEAD")) { error in
            XCTAssertTrue((error as NSError).localizedDescription.contains("标签名称不能为空"))
        }
    }

    func testAheadBehindCountsLocalAndRemoteCommits() throws {
        let remote = try TestGitRepository()
        try remote.write("README.md", content: "hello\n")
        try remote.run(["add", "."])
        try remote.run(["commit", "-m", "initial"])

        let destinationRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: destinationRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: destinationRoot) }

        let localURL = destinationRoot.appendingPathComponent("local", isDirectory: true)
        try GitRepositoryCLI.clone(remoteURL: remote.url.path, destinationURL: localURL)

        let local = TestGitRepository(url: localURL)
        try local.run(["config", "user.name", "Test User"])
        try local.run(["config", "user.email", "test@example.com"])

        let client = GitRepositoryCLI(repositoryURL: localURL)
        XCTAssertEqual(try client.aheadBehind(), GitAheadBehind(ahead: 0, behind: 0, hasUpstream: true))

        try local.write("local.txt", content: "local\n")
        try local.run(["add", "."])
        try local.run(["commit", "-m", "local change"])
        XCTAssertEqual(try client.aheadBehind(), GitAheadBehind(ahead: 1, behind: 0, hasUpstream: true))

        try remote.write("remote.txt", content: "remote\n")
        try remote.run(["add", "."])
        try remote.run(["commit", "-m", "remote change"])
        try client.fetch()

        XCTAssertEqual(try client.aheadBehind(), GitAheadBehind(ahead: 1, behind: 1, hasUpstream: true))
    }

    func testMergeConflictLifecycle() throws {
        let repo = try TestGitRepository()
        try repo.write("shared.txt", content: "base\n")
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "base"])

        try repo.run(["checkout", "-b", "feature"])
        try repo.write("shared.txt", content: "feature\n")
        try repo.run(["commit", "-am", "feature change"])

        try repo.run(["checkout", "master"])
        try repo.write("shared.txt", content: "master\n")
        try repo.run(["commit", "-am", "master change"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)

        XCTAssertThrowsError(try repo.run(["merge", "feature"])) { _ in }
        XCTAssertTrue(try client.isMerging())
        XCTAssertEqual(try client.getCurrentMergeBranchName(), "feature")
        XCTAssertEqual(try client.getMergeConflictFiles(), ["shared.txt"])

        let unresolvedFiles = try client.mergeResolutionFiles()
        XCTAssertEqual(unresolvedFiles, [GitMergeFile(path: "shared.txt", state: .unresolved)])
        XCTAssertFalse(try client.canContinueMerge())

        try repo.write("shared.txt", content: "resolved\n")
        try client.addFiles(["shared.txt"])

        let stagedFiles = try client.mergeResolutionFiles()
        XCTAssertEqual(stagedFiles, [GitMergeFile(path: "shared.txt", state: .staged)])
        XCTAssertTrue(try client.canContinueMerge())

        try client.continueMerge()
        XCTAssertFalse(try client.isMerging())
    }

    func testGetCurrentMergeBranchNameReturnsNilOutsideMerge() throws {
        let repo = try TestGitRepository()
        try repo.run(["commit", "--allow-empty", "-m", "initial"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)
        XCTAssertFalse(try client.isMerging())
        XCTAssertNil(try client.getCurrentMergeBranchName())
    }

    func testGetCurrentMergeBranchNameFallsBackToMergeMessage() throws {
        let repo = try TestGitRepository()
        try repo.write("shared.txt", content: "base\n")
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "base"])

        try repo.run(["checkout", "-b", "feature"])
        try repo.write("shared.txt", content: "feature\n")
        try repo.run(["commit", "-am", "feature change"])

        try repo.run(["checkout", "master"])
        try repo.write("shared.txt", content: "master\n")
        try repo.run(["commit", "-am", "master change"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)
        XCTAssertThrowsError(try repo.run(["merge", "feature"])) { _ in }
        try repo.run(["branch", "-D", "feature"])

        XCTAssertEqual(try client.getCurrentMergeBranchName(), "feature")
    }

    func testContinueMergeThrowsUntilFilesAreStaged() throws {
        let repo = try TestGitRepository()
        try repo.write("shared.txt", content: "base\n")
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "base"])

        try repo.run(["checkout", "-b", "feature"])
        try repo.write("shared.txt", content: "feature\n")
        try repo.run(["commit", "-am", "feature change"])

        try repo.run(["checkout", "master"])
        try repo.write("shared.txt", content: "master\n")
        try repo.run(["commit", "-am", "master change"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)
        XCTAssertThrowsError(try repo.run(["merge", "feature"])) { _ in }

        try repo.write("shared.txt", content: "resolved but unstaged\n")

        XCTAssertThrowsError(try client.continueMerge())
        XCTAssertTrue(try client.isMerging())
        XCTAssertFalse(try client.canContinueMerge())
    }

    func testMergeResolutionFilesStayUnresolvedUntilStaged() throws {
        let repo = try TestGitRepository()
        try repo.write("shared.txt", content: "base\n")
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "base"])

        try repo.run(["checkout", "-b", "feature"])
        try repo.write("shared.txt", content: "feature\n")
        try repo.run(["commit", "-am", "feature change"])

        try repo.run(["checkout", "master"])
        try repo.write("shared.txt", content: "master\n")
        try repo.run(["commit", "-am", "master change"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)
        XCTAssertThrowsError(try repo.run(["merge", "feature"])) { _ in }

        try repo.write("shared.txt", content: "resolved but unstaged\n")

        XCTAssertEqual(
            try client.mergeResolutionFiles(),
            [GitMergeFile(path: "shared.txt", state: .unresolved)]
        )
        XCTAssertFalse(try client.canContinueMerge())

        try client.addFiles(["shared.txt"])
        XCTAssertEqual(
            try client.mergeResolutionFiles(),
            [GitMergeFile(path: "shared.txt", state: .staged)]
        )
        XCTAssertTrue(try client.canContinueMerge())
    }

    func testAbortMergeRestoresRepositoryState() throws {
        let repo = try TestGitRepository()
        try repo.write("shared.txt", content: "base\n")
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "base"])

        try repo.run(["checkout", "-b", "feature"])
        try repo.write("shared.txt", content: "feature\n")
        try repo.run(["commit", "-am", "feature change"])

        try repo.run(["checkout", "master"])
        try repo.write("shared.txt", content: "master\n")
        try repo.run(["commit", "-am", "master change"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)
        XCTAssertThrowsError(try repo.run(["merge", "feature"])) { _ in }
        XCTAssertTrue(try client.isMerging())

        try client.abortMerge()

        XCTAssertFalse(try client.isMerging())
        XCTAssertEqual(try client.getMergeConflictFiles(), [])
        XCTAssertEqual(try repo.read("shared.txt"), "master\n")
    }

    func testAbortMergeOutsideMergeThrows() throws {
        let repo = try TestGitRepository()
        try repo.run(["commit", "--allow-empty", "-m", "initial"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)
        XCTAssertThrowsError(try client.abortMerge())
    }

    func testRunGitPrefersStderrInThrownError() throws {
        let repo = try TestGitRepository()
        let client = GitRepositoryCLI(repositoryURL: repo.url)

        XCTAssertThrowsError(try client.runGit(["not-a-real-command"])) { error in
            let description = (error as NSError).localizedDescription
            XCTAssertTrue(description.contains("not-a-real-command"))
        }
    }

    func testInitializeCreatesGitRepository() throws {
        let destinationRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: destinationRoot) }

        let repositoryURL = destinationRoot.appendingPathComponent("new-repo", isDirectory: true)
        try GitRepositoryCLI.initialize(at: repositoryURL)

        XCTAssertTrue(FileManager.default.fileExists(atPath: repositoryURL.appendingPathComponent(".git").path))
    }

    func testUnstageFilesMovesTrackedFileOutOfIndex() throws {
        let repo = try TestGitRepository()
        try repo.write("README.md", content: "base\n")
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "initial"])

        try repo.write("README.md", content: "changed\n")
        let client = GitRepositoryCLI(repositoryURL: repo.url)
        try client.addFiles(["README.md"])
        XCTAssertEqual(try client.statusEntries(), [GitStatusEntry(path: "README.md", indexStatus: "M", workTreeStatus: " ")])

        try client.unstageFiles(["README.md"])

        XCTAssertEqual(try client.statusEntries(), [GitStatusEntry(path: "README.md", indexStatus: " ", workTreeStatus: "M")])
    }

    func testUnstageFilesHandlesInitialRepositoryWithoutHead() throws {
        let destinationRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: destinationRoot) }

        let repositoryURL = destinationRoot.appendingPathComponent("new-repo", isDirectory: true)
        try GitRepositoryCLI.initialize(at: repositoryURL)
        let repo = TestGitRepository(url: repositoryURL)
        try repo.write("README.md", content: "hello\n")

        let client = GitRepositoryCLI(repositoryURL: repositoryURL)
        try client.addFiles(["README.md"])
        try client.unstageFiles(["README.md"])

        XCTAssertEqual(try client.statusEntries(), [GitStatusEntry(path: "README.md", indexStatus: "?", workTreeStatus: "?")])
    }

    func testDiscardFileChangesRestoresTrackedFileAndIndex() throws {
        let repo = try TestGitRepository()
        try repo.write("README.md", content: "base\n")
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "initial"])

        try repo.write("README.md", content: "staged\n")
        try repo.run(["add", "README.md"])
        try repo.write("README.md", content: "unstaged\n")

        let client = GitRepositoryCLI(repositoryURL: repo.url)
        XCTAssertEqual(try client.statusEntries(), [GitStatusEntry(path: "README.md", indexStatus: "M", workTreeStatus: "M")])

        try client.discardFileChanges("README.md")

        XCTAssertEqual(try repo.read("README.md"), "base\n")
        XCTAssertEqual(try client.statusEntries(), [])
    }

    func testDiscardFileChangesRemovesStagedNewFile() throws {
        let repo = try TestGitRepository()
        try repo.run(["commit", "--allow-empty", "-m", "initial"])
        try repo.write("new.txt", content: "new\n")
        try repo.run(["add", "new.txt"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)
        XCTAssertEqual(try client.statusEntries(), [GitStatusEntry(path: "new.txt", indexStatus: "A", workTreeStatus: " ")])

        try client.discardFileChanges("new.txt")

        XCTAssertNil(try repo.read("new.txt"))
        XCTAssertEqual(try client.statusEntries(), [])
    }

    func testDiscardAllChangesRestoresTrackedAndRemovesNewFiles() throws {
        let repo = try TestGitRepository()
        try repo.write("README.md", content: "base\n")
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "initial"])

        try repo.write("README.md", content: "changed\n")
        try repo.write("staged-new.txt", content: "new\n")
        try repo.run(["add", "README.md", "staged-new.txt"])
        try repo.write("untracked.txt", content: "scratch\n")

        let client = GitRepositoryCLI(repositoryURL: repo.url)
        try client.discardAllChanges()

        XCTAssertEqual(try repo.read("README.md"), "base\n")
        XCTAssertNil(try repo.read("staged-new.txt"))
        XCTAssertNil(try repo.read("untracked.txt"))
        XCTAssertEqual(try client.statusEntries(), [])
    }

    func testCreateRepositoryWritesFilesAndInitialCommit() throws {
        let destinationRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: destinationRoot) }

        let repositoryURL = destinationRoot.appendingPathComponent("created-repo", isDirectory: true)
        try GitRepositoryCLI.create(
            at: repositoryURL,
            options: .init(
                readmeContent: "# Created Repo\n",
                gitignoreContent: "DerivedData/\n",
                licenseContent: "MIT License\n",
                initialCommitMessage: "Initial commit",
                userName: "Test User",
                userEmail: "test@example.com"
            )
        )

        let repo = TestGitRepository(url: repositoryURL)
        XCTAssertEqual(try repo.read("README.md"), "# Created Repo\n")
        XCTAssertEqual(try repo.read(".gitignore"), "DerivedData/\n")
        XCTAssertEqual(try repo.read("LICENSE"), "MIT License\n")
        XCTAssertEqual(try repo.run(["log", "--oneline", "--format=%s"]), "Initial commit")
    }

    func testCloneRepositoryIntoNewDirectory() throws {
        let remote = try TestGitRepository()
        try remote.write("README.md", content: "hello\n")
        try remote.run(["add", "."])
        try remote.run(["commit", "-m", "initial"])

        let destinationRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: destinationRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: destinationRoot) }

        let destinationURL = destinationRoot.appendingPathComponent("cloned-repo", isDirectory: true)
        try GitRepositoryCLI.clone(remoteURL: remote.url.path, destinationURL: destinationURL)

        XCTAssertTrue(FileManager.default.fileExists(atPath: destinationURL.appendingPathComponent(".git").path))
        XCTAssertEqual(try String(contentsOf: destinationURL.appendingPathComponent("README.md"), encoding: .utf8), "hello\n")
    }

    func testCloneFailureRemovesNewlyCreatedDestinationDirectory() throws {
        let destinationRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: destinationRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: destinationRoot) }

        let destinationURL = destinationRoot.appendingPathComponent("missing-repo", isDirectory: true)

        XCTAssertThrowsError(try GitRepositoryCLI.clone(remoteURL: "/tmp/definitely-missing-repo", destinationURL: destinationURL))
        XCTAssertFalse(FileManager.default.fileExists(atPath: destinationURL.path))
    }

    func testCloneFailureKeepsPreexistingDestinationDirectory() throws {
        let destinationRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: destinationRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: destinationRoot) }

        let destinationURL = destinationRoot.appendingPathComponent("existing-empty-dir", isDirectory: true)
        try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true)

        XCTAssertThrowsError(try GitRepositoryCLI.clone(remoteURL: "/tmp/definitely-missing-repo", destinationURL: destinationURL))
        XCTAssertTrue(FileManager.default.fileExists(atPath: destinationURL.path))
    }

    func testCloneCreatesParentDirectoryWhenItDoesNotExist() throws {
        let remote = try TestGitRepository()
        try remote.write("README.md", content: "hello\n")
        try remote.run(["add", "."])
        try remote.run(["commit", "-m", "initial"])

        let destinationRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        // Do NOT create destinationRoot - it should be created automatically
        defer { try? FileManager.default.removeItem(at: destinationRoot) }

        let destinationURL = destinationRoot.appendingPathComponent("cloned-repo", isDirectory: true)
        try GitRepositoryCLI.clone(remoteURL: remote.url.path, destinationURL: destinationURL)

        XCTAssertTrue(FileManager.default.fileExists(atPath: destinationURL.appendingPathComponent(".git").path))
        XCTAssertEqual(try String(contentsOf: destinationURL.appendingPathComponent("README.md"), encoding: .utf8), "hello\n")
    }

}

private final class TestGitRepository {
    let url: URL

    init() throws {
        let base = FileManager.default.temporaryDirectory
        let directory = base.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        url = directory

        try run(["init", "-b", "master"])
        try run(["config", "user.name", "Test User"])
        try run(["config", "user.email", "test@example.com"])
    }

    init(url: URL) {
        self.url = url
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }

    func write(_ relativePath: String, content: String) throws {
        let fileURL = url.appendingPathComponent(relativePath)
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try content.data(using: .utf8)?.write(to: fileURL)
    }

    func read(_ relativePath: String) throws -> String? {
        let fileURL = url.appendingPathComponent(relativePath)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        return try String(contentsOf: fileURL, encoding: .utf8)
    }

    @discardableResult
    func run(_ arguments: [String], allowNonZeroExit: Bool = false) throws -> String {
        let process = Process()
        process.currentDirectoryURL = url
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["git"] + arguments

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        let stdout = String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

        guard allowNonZeroExit || process.terminationStatus == 0 else {
            let message = stderr.isEmpty ? stdout : stderr
            throw NSError(domain: "TestGitRepository", code: Int(process.terminationStatus), userInfo: [
                NSLocalizedDescriptionKey: message
            ])
        }

        return stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
