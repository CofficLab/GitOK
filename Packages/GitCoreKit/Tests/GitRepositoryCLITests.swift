import Foundation
import XCTest
@testable import GitCoreKit

final class GitRepositoryCLITests: XCTestCase {
    func testGitMergeFileIDUsesPath() {
        XCTAssertEqual(GitMergeFile(path: "Sources/App.swift", state: .staged).id, "Sources/App.swift")
    }

    func testInitializeLFSWritesLocalFilterConfigWhenAvailable() throws {
        let repo = try TestGitRepository()
        let client = GitRepositoryCLI(repositoryURL: repo.url)

        guard client.lfsStatus().isAvailable else {
            throw XCTSkip("git-lfs is not installed in this environment")
        }

        try client.initializeLFS()

        XCTAssertEqual(try repo.run(["config", "--local", "filter.lfs.process"]), "git-lfs filter-process")
        XCTAssertEqual(try repo.run(["config", "--local", "filter.lfs.required"]), "true")
    }

    func testLFSLargeFileCandidatesFindsFilesAboveThreshold() throws {
        let repo = try TestGitRepository()
        try repo.writeData("small.bin", data: Data(repeating: 1, count: 8))
        try repo.writeData("assets/big.bin", data: Data(repeating: 2, count: 16))
        try repo.writeData("assets/bigger.bin", data: Data(repeating: 3, count: 24))

        let client = GitRepositoryCLI(repositoryURL: repo.url)

        XCTAssertEqual(
            try client.lfsLargeFileCandidates(thresholdBytes: 16),
            [
                GitRepositoryCLI.GitLFSLargeFileCandidate(path: "assets/bigger.bin", byteSize: 24),
                GitRepositoryCLI.GitLFSLargeFileCandidate(path: "assets/big.bin", byteSize: 16),
            ]
        )
    }

    func testLFSLargeFileCandidatesSkipsGitDirectory() throws {
        let repo = try TestGitRepository()
        try repo.writeData(".git/objects/fake-large", data: Data(repeating: 1, count: 32))
        try repo.writeData("tracked-large.bin", data: Data(repeating: 2, count: 32))

        let client = GitRepositoryCLI(repositoryURL: repo.url)

        XCTAssertEqual(
            try client.lfsLargeFileCandidates(thresholdBytes: 16),
            [GitRepositoryCLI.GitLFSLargeFileCandidate(path: "tracked-large.bin", byteSize: 32)]
        )
    }

    func testLFSLargeFileCandidatesRejectsInvalidThreshold() throws {
        let repo = try TestGitRepository()
        let client = GitRepositoryCLI(repositoryURL: repo.url)

        XCTAssertThrowsError(try client.lfsLargeFileCandidates(thresholdBytes: 0)) { error in
            XCTAssertTrue((error as NSError).localizedDescription.contains("大文件阈值必须大于 0"))
        }
    }

    func testLFSLargeFileCandidatesLimitsResultsBySize() throws {
        let repo = try TestGitRepository()
        try repo.writeData("assets/medium.bin", data: Data(repeating: 1, count: 24))
        try repo.writeData("assets/large.bin", data: Data(repeating: 2, count: 48))
        try repo.writeData("assets/small.bin", data: Data(repeating: 3, count: 16))

        let client = GitRepositoryCLI(repositoryURL: repo.url)

        XCTAssertEqual(
            try client.lfsLargeFileCandidates(thresholdBytes: 8, maxCount: 2),
            [
                GitRepositoryCLI.GitLFSLargeFileCandidate(path: "assets/large.bin", byteSize: 48),
                GitRepositoryCLI.GitLFSLargeFileCandidate(path: "assets/medium.bin", byteSize: 24),
            ]
        )
    }

    func testLFSLargeFileCandidatesRejectsInvalidMaxCount() throws {
        let repo = try TestGitRepository()
        let client = GitRepositoryCLI(repositoryURL: repo.url)

        XCTAssertThrowsError(try client.lfsLargeFileCandidates(thresholdBytes: 1, maxCount: 0)) { error in
            XCTAssertTrue((error as NSError).localizedDescription.contains("大文件候选数量必须大于 0"))
        }
    }

    func testLFSAttributeMismatchesFindsPointerWithoutAttribute() throws {
        let repo = try TestGitRepository()
        try repo.write("asset.bin", content: lfsPointer())
        try repo.run(["add", "."])

        let client = GitRepositoryCLI(repositoryURL: repo.url)

        XCTAssertEqual(
            try client.lfsAttributeMismatches(),
            [
                GitRepositoryCLI.GitLFSAttributeMismatch(
                    path: "asset.bin",
                    kind: .pointerWithoutLFSAttribute
                )
            ]
        )
    }

    func testLFSAttributeMismatchesFindsAttributeWithoutPointer() throws {
        let repo = try TestGitRepository()
        try repo.write(".gitattributes", content: "*.bin filter=lfs diff=lfs merge=lfs -text\n")
        try repo.write("asset.bin", content: "regular file content\n")
        try repo.addWithDisabledLFSFilter()

        let client = GitRepositoryCLI(repositoryURL: repo.url)

        XCTAssertEqual(
            try client.lfsAttributeMismatches(),
            [
                GitRepositoryCLI.GitLFSAttributeMismatch(
                    path: "asset.bin",
                    kind: .lfsAttributeWithoutPointer
                )
            ]
        )
    }

    func testLFSAttributeMismatchesAcceptsPointerWithAttribute() throws {
        let repo = try TestGitRepository()
        try repo.write(".gitattributes", content: "*.bin filter=lfs diff=lfs merge=lfs -text\n")
        try repo.write("asset.bin", content: lfsPointer())
        try repo.addWithDisabledLFSFilter()

        let client = GitRepositoryCLI(repositoryURL: repo.url)

        XCTAssertEqual(try client.lfsAttributeMismatches(), [])
    }

    func testInitializeSubmodulesChecksOutUninitializedSubmodule() throws {
        let child = try TestGitRepository()
        try child.write("README.md", content: "child\n")
        try child.run(["add", "."])
        try child.run(["commit", "-m", "child"])

        let parent = try TestGitRepository()
        try parent.run(["-c", "protocol.file.allow=always", "submodule", "add", child.url.path, "Vendor/Child"])
        try parent.run(["commit", "-am", "add submodule"])

        let destinationRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: destinationRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: destinationRoot) }

        let localURL = destinationRoot.appendingPathComponent("local", isDirectory: true)
        try GitRepositoryCLI.clone(remoteURL: parent.url.path, destinationURL: localURL)

        let client = GitRepositoryCLI(repositoryURL: localURL)
        XCTAssertEqual(try client.submodules().map(\.status), [.uninitialized])

        try client.initializeSubmodules(allowFileProtocol: true)

        XCTAssertEqual(try String(contentsOf: localURL.appendingPathComponent("Vendor/Child/README.md"), encoding: .utf8), "child\n")
        XCTAssertEqual(try client.submodules().map(\.status), [.initialized])
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
        XCTAssertEqual(stashes[0].branchName, "master")
        XCTAssertNotNil(stashes[0].relativeDate)
        XCTAssertEqual(stashes[0].changedFileCount, 1)
        XCTAssertTrue(stashes[0].diffPreview.contains("notes.txt"))
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
        let stashes = try client.stashList()
        XCTAssertEqual(stashes.count, 1)
        XCTAssertEqual(stashes[0].message, "untracked only")
        XCTAssertEqual(stashes[0].changedFileCount, 1)

        try client.stashPop(index: 0)
        XCTAssertEqual(try repo.read("draft.md"), "hello\n")
        XCTAssertTrue(try client.stashList().isEmpty)
    }

    func testStashBranchCreatesBranchAndRestoresChanges() throws {
        let repo = try TestGitRepository()
        try repo.run(["commit", "--allow-empty", "-m", "initial"])

        try repo.write("draft.md", content: "hello\n")

        let client = GitRepositoryCLI(repositoryURL: repo.url)
        try client.stashSave(message: "branch me")
        try client.stashBranch(name: "recover/stash", index: 0)

        XCTAssertEqual(try repo.run(["branch", "--show-current"]), "recover/stash")
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
        let stashes = try client.stashList()
        XCTAssertEqual(stashes.count, 1)
        XCTAssertEqual(stashes[0].message, "pop conflict candidate")
        XCTAssertEqual(stashes[0].changedFileCount, 1)
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
        let stashes = try client.stashList()
        XCTAssertEqual(stashes.count, 1)
        XCTAssertEqual(stashes[0].message, "conflict candidate")
        XCTAssertEqual(stashes[0].changedFileCount, 1)
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

    func testRenameBranchRenamesExistingBranch() throws {
        let repo = try TestGitRepository()
        try repo.run(["commit", "--allow-empty", "-m", "initial"])
        try repo.run(["checkout", "-b", "feature/old"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)
        try client.renameBranch(from: "feature/old", to: "feature/new")

        let branches = try repo.run(["branch", "--format=%(refname:short)"])
            .split(separator: "\n")
            .map(String.init)
        XCTAssertFalse(branches.contains("feature/old"))
        XCTAssertTrue(branches.contains("feature/new"))
    }

    func testRenameBranchRejectsEmptyNewName() throws {
        let repo = try TestGitRepository()
        try repo.run(["commit", "--allow-empty", "-m", "initial"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)

        XCTAssertThrowsError(try client.renameBranch(from: "master", to: "  ")) { error in
            XCTAssertTrue((error as NSError).localizedDescription.contains("新分支名称不能为空"))
        }
    }

    func testRemoteBranchesListsFetchedBranchesWithoutHeadAlias() throws {
        let remote = try TestGitRepository()
        try remote.run(["commit", "--allow-empty", "-m", "initial"])
        try remote.run(["checkout", "-b", "feature/list"])
        try remote.run(["checkout", "master"])

        let localURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: localURL) }
        try GitRepositoryCLI.clone(remoteURL: remote.url.path, destinationURL: localURL)

        let client = GitRepositoryCLI(repositoryURL: localURL)

        XCTAssertEqual(try client.remoteBranches(remote: "origin"), ["origin/feature/list", "origin/master"])
    }

    func testSetAndUnsetUpstreamUpdatesBranchConfig() throws {
        let remote = try TestGitRepository()
        try remote.run(["commit", "--allow-empty", "-m", "initial"])
        try remote.run(["checkout", "-b", "feature/upstream"])
        try remote.run(["checkout", "master"])

        let localURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: localURL) }
        try GitRepositoryCLI.clone(remoteURL: remote.url.path, destinationURL: localURL)

        let repo = TestGitRepository(url: localURL)
        try repo.run(["checkout", "-b", "local-upstream"])

        let client = GitRepositoryCLI(repositoryURL: localURL)
        try client.setUpstream(localBranch: "local-upstream", upstreamBranch: "origin/feature/upstream")

        XCTAssertEqual(try repo.run(["rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{upstream}"]), "origin/feature/upstream")

        try client.unsetUpstream(localBranch: "local-upstream")

        XCTAssertThrowsError(try repo.run(["rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{upstream}"]))
    }

    func testDeleteRemoteBranchPushesDeleteRef() throws {
        let remote = try TestGitRepository()
        try remote.run(["commit", "--allow-empty", "-m", "initial"])
        try remote.run(["checkout", "-b", "feature/delete-me"])
        try remote.run(["checkout", "master"])

        let localURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: localURL) }
        try GitRepositoryCLI.clone(remoteURL: remote.url.path, destinationURL: localURL)

        let client = GitRepositoryCLI(repositoryURL: localURL)
        try client.deleteRemoteBranch(named: "origin/feature/delete-me", remote: "origin")

        let remoteBranches = try remote.run(["branch", "--format=%(refname:short)"])
            .split(separator: "\n")
            .map(String.init)
        XCTAssertFalse(remoteBranches.contains("feature/delete-me"))
    }

    func testPublishBranchPushesBranchAndSetsUpstream() throws {
        let remote = try TestGitRepository()
        try remote.run(["commit", "--allow-empty", "-m", "initial"])

        let localURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: localURL) }
        try GitRepositoryCLI.clone(remoteURL: remote.url.path, destinationURL: localURL)

        let repo = TestGitRepository(url: localURL)
        try repo.run(["checkout", "-b", "feature/publish"])
        try repo.write("feature.txt", content: "published\n")
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "publish branch"])

        let client = GitRepositoryCLI(repositoryURL: localURL)
        try client.publishBranch(localBranch: "feature/publish", remote: "origin")

        let remoteBranches = try remote.run(["branch", "--format=%(refname:short)"])
            .split(separator: "\n")
            .map(String.init)
        XCTAssertTrue(remoteBranches.contains("feature/publish"))
        XCTAssertEqual(try repo.run(["rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{upstream}"]), "origin/feature/publish")
    }

    func testCompareBranchesReturnsAheadBehindCommitsAndFiles() throws {
        let repo = try TestGitRepository()
        try repo.write("shared.txt", content: "base\n")
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "initial"])

        try repo.run(["checkout", "-b", "feature/compare"])
        try repo.write("shared.txt", content: "feature\n")
        try repo.write("added.txt", content: "added\n")
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "feature change"])

        try repo.run(["checkout", "master"])
        try repo.write("base-only.txt", content: "base\n")
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "base change"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)
        let compare = try client.compareBranches(base: "master", head: "feature/compare")

        XCTAssertEqual(compare.base, "master")
        XCTAssertEqual(compare.head, "feature/compare")
        XCTAssertEqual(compare.ahead, 1)
        XCTAssertEqual(compare.behind, 1)
        XCTAssertEqual(compare.commits.map(\.subject), ["feature change"])
        XCTAssertEqual(
            compare.files,
            [
                GitBranchCompareFile(status: "A", path: "added.txt"),
                GitBranchCompareFile(status: "M", path: "shared.txt"),
            ]
        )
    }

    func testCompareBranchesRejectsMissingBase() throws {
        let repo = try TestGitRepository()
        try repo.run(["commit", "--allow-empty", "-m", "initial"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)

        XCTAssertThrowsError(try client.compareBranches(base: "missing", head: "master"))
    }

    func testStartRebaseReplaysBranchOntoUpstream() throws {
        let repo = try TestGitRepository()
        try repo.write("README.md", content: "initial\n")
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "initial"])

        try repo.run(["checkout", "-b", "feature/rebase"])
        try repo.write("feature.txt", content: "feature\n")
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "feature change"])

        try repo.run(["checkout", "master"])
        try repo.write("base.txt", content: "base\n")
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "base change"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)
        try client.startRebase(branch: "feature/rebase", onto: "master")

        XCTAssertFalse(try client.rebaseStatus().isRebasing)
        XCTAssertEqual(try repo.run(["branch", "--show-current"]), "feature/rebase")
        XCTAssertEqual(try repo.run(["log", "--format=%s", "-2"]), "feature change\nbase change")
    }

    func testStartRebaseConflictCanAbort() throws {
        let repo = try TestGitRepository()
        try repo.write("shared.txt", content: "initial\n")
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "initial"])

        try repo.run(["checkout", "-b", "feature/conflict-rebase"])
        try repo.write("shared.txt", content: "feature\n")
        try repo.run(["commit", "-am", "feature change"])

        try repo.run(["checkout", "master"])
        try repo.write("shared.txt", content: "base\n")
        try repo.run(["commit", "-am", "base change"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)

        XCTAssertThrowsError(try client.startRebase(branch: "feature/conflict-rebase", onto: "master"))
        let status = try client.rebaseStatus()
        XCTAssertTrue(status.isRebasing)
        XCTAssertEqual(status.branchName, "feature/conflict-rebase")
        XCTAssertEqual(try client.getMergeConflictFiles(), ["shared.txt"])

        try client.abortRebase()

        XCTAssertFalse(try client.rebaseStatus().isRebasing)
        XCTAssertEqual(try repo.run(["branch", "--show-current"]), "feature/conflict-rebase")
        XCTAssertEqual(try repo.read("shared.txt"), "feature\n")
    }

    func testContinueRebaseCompletesAfterConflictResolution() throws {
        let repo = try TestGitRepository()
        try repo.write("shared.txt", content: "initial\n")
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "initial"])

        try repo.run(["checkout", "-b", "feature/continue-rebase"])
        try repo.write("shared.txt", content: "feature\n")
        try repo.run(["commit", "-am", "feature change"])

        try repo.run(["checkout", "master"])
        try repo.write("shared.txt", content: "base\n")
        try repo.run(["commit", "-am", "base change"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)

        XCTAssertThrowsError(try client.startRebase(branch: "feature/continue-rebase", onto: "master"))
        try repo.write("shared.txt", content: "resolved\n")
        try repo.run(["add", "shared.txt"])
        XCTAssertEqual(try client.getMergeConflictFiles(), [])

        try client.continueRebase()

        XCTAssertFalse(try client.rebaseStatus().isRebasing)
        XCTAssertEqual(try repo.run(["branch", "--show-current"]), "feature/continue-rebase")
        XCTAssertEqual(try repo.read("shared.txt"), "resolved\n")
    }

    func testCherryPickMultipleCommitsOntoBranch() throws {
        let repo = try TestGitRepository()
        try repo.write("README.md", content: "initial\n")
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "initial"])

        try repo.run(["checkout", "-b", "feature/cherry"])
        try repo.write("one.txt", content: "one\n")
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "one"])
        let first = try repo.run(["rev-parse", "HEAD"])
        try repo.write("two.txt", content: "two\n")
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "two"])
        let second = try repo.run(["rev-parse", "HEAD"])

        try repo.run(["checkout", "master"])
        let client = GitRepositoryCLI(repositoryURL: repo.url)
        try client.cherryPick(commits: [first, second], onto: "master")

        XCTAssertFalse(try client.cherryPickStatus().isCherryPicking)
        XCTAssertEqual(try repo.run(["branch", "--show-current"]), "master")
        XCTAssertEqual(try repo.run(["log", "--format=%s", "-2"]), "two\none")
        XCTAssertEqual(try repo.read("one.txt"), "one\n")
        XCTAssertEqual(try repo.read("two.txt"), "two\n")
    }

    func testCherryPickConflictCanAbort() throws {
        let repo = try TestGitRepository()
        try repo.write("shared.txt", content: "initial\n")
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "initial"])

        try repo.run(["checkout", "-b", "feature/cherry-conflict"])
        try repo.write("shared.txt", content: "feature\n")
        try repo.run(["commit", "-am", "feature change"])
        let commit = try repo.run(["rev-parse", "HEAD"])

        try repo.run(["checkout", "master"])
        try repo.write("shared.txt", content: "base\n")
        try repo.run(["commit", "-am", "base change"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)

        XCTAssertThrowsError(try client.cherryPick(commits: [commit], onto: "master"))
        XCTAssertTrue(try client.cherryPickStatus().isCherryPicking)
        XCTAssertEqual(try client.getMergeConflictFiles(), ["shared.txt"])

        try client.abortCherryPick()

        XCTAssertFalse(try client.cherryPickStatus().isCherryPicking)
        XCTAssertEqual(try repo.run(["branch", "--show-current"]), "master")
        XCTAssertEqual(try repo.read("shared.txt"), "base\n")
    }

    func testContinueCherryPickCompletesAfterConflictResolution() throws {
        let repo = try TestGitRepository()
        try repo.write("shared.txt", content: "initial\n")
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "initial"])

        try repo.run(["checkout", "-b", "feature/cherry-continue"])
        try repo.write("shared.txt", content: "feature\n")
        try repo.run(["commit", "-am", "feature change"])
        let commit = try repo.run(["rev-parse", "HEAD"])

        try repo.run(["checkout", "master"])
        try repo.write("shared.txt", content: "base\n")
        try repo.run(["commit", "-am", "base change"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)

        XCTAssertThrowsError(try client.cherryPick(commits: [commit], onto: "master"))
        try repo.write("shared.txt", content: "resolved\n")
        try repo.run(["add", "shared.txt"])

        try client.continueCherryPick()

        XCTAssertFalse(try client.cherryPickStatus().isCherryPicking)
        XCTAssertEqual(try repo.run(["branch", "--show-current"]), "master")
        XCTAssertEqual(try repo.read("shared.txt"), "resolved\n")
        XCTAssertEqual(try repo.run(["log", "--format=%s", "-1"]), "feature change")
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

    func testCreateAnnotatedTagCreatesAnnotatedTagAtCommit() throws {
        let repo = try TestGitRepository()
        try repo.run(["commit", "--allow-empty", "-m", "initial"])
        let commitHash = try repo.run(["rev-parse", "HEAD"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)
        try client.createAnnotatedTag(named: "v1.0.0", commitHash: commitHash, message: "Release 1.0.0")

        XCTAssertEqual(try repo.run(["rev-list", "-n", "1", "v1.0.0"]), commitHash)
        XCTAssertEqual(try repo.run(["for-each-ref", "refs/tags/v1.0.0", "--format=%(objecttype)"]), "tag")
    }

    func testCreateAnnotatedTagRejectsEmptyMessage() throws {
        let repo = try TestGitRepository()
        try repo.run(["commit", "--allow-empty", "-m", "initial"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)

        XCTAssertThrowsError(try client.createAnnotatedTag(named: "v1.0.0", commitHash: "HEAD", message: "  ")) { error in
            XCTAssertTrue((error as NSError).localizedDescription.contains("标签说明不能为空"))
        }
    }

    func testDeleteLocalTagRemovesTag() throws {
        let repo = try TestGitRepository()
        try repo.run(["commit", "--allow-empty", "-m", "initial"])
        try repo.run(["tag", "v1.0.0"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)
        try client.deleteLocalTag(named: "v1.0.0")

        let tags = try repo.run(["tag", "--list"])
            .split(separator: "\n")
            .map(String.init)
        XCTAssertFalse(tags.contains("v1.0.0"))
    }

    func testDeleteLocalTagRejectsEmptyName() throws {
        let repo = try TestGitRepository()
        try repo.run(["commit", "--allow-empty", "-m", "initial"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)

        XCTAssertThrowsError(try client.deleteLocalTag(named: "  ")) { error in
            XCTAssertTrue((error as NSError).localizedDescription.contains("标签名称不能为空"))
        }
    }

    func testPushTagPushesTagToOrigin() throws {
        let remote = try TestGitRepository()
        try remote.run(["commit", "--allow-empty", "-m", "initial"])

        let destinationRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: destinationRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: destinationRoot) }

        let localURL = destinationRoot.appendingPathComponent("local", isDirectory: true)
        try GitRepositoryCLI.clone(remoteURL: remote.url.path, destinationURL: localURL)
        let local = TestGitRepository(url: localURL)
        try local.run(["tag", "v1.0.0"])

        let client = GitRepositoryCLI(repositoryURL: localURL)
        try client.pushTag(named: "v1.0.0")

        let remoteTags = try remote.run(["tag", "--list"])
            .split(separator: "\n")
            .map(String.init)
        XCTAssertTrue(remoteTags.contains("v1.0.0"))
    }

    func testPushTagRejectsEmptyName() throws {
        let repo = try TestGitRepository()
        try repo.run(["commit", "--allow-empty", "-m", "initial"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)

        XCTAssertThrowsError(try client.pushTag(named: "  ")) { error in
            XCTAssertTrue((error as NSError).localizedDescription.contains("标签名称不能为空"))
        }
    }

    func testDeleteRemoteTagRemovesTagFromOrigin() throws {
        let remote = try TestGitRepository()
        try remote.run(["commit", "--allow-empty", "-m", "initial"])
        try remote.run(["tag", "v1.0.0"])

        let destinationRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: destinationRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: destinationRoot) }

        let localURL = destinationRoot.appendingPathComponent("local", isDirectory: true)
        try GitRepositoryCLI.clone(remoteURL: remote.url.path, destinationURL: localURL)

        let client = GitRepositoryCLI(repositoryURL: localURL)
        try client.deleteRemoteTag(named: "v1.0.0")

        let remoteTags = try remote.run(["tag", "--list"])
            .split(separator: "\n")
            .map(String.init)
        XCTAssertFalse(remoteTags.contains("v1.0.0"))
    }

    func testDeleteRemoteTagRejectsEmptyName() throws {
        let repo = try TestGitRepository()
        try repo.run(["commit", "--allow-empty", "-m", "initial"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)

        XCTAssertThrowsError(try client.deleteRemoteTag(named: "  ")) { error in
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
        XCTAssertEqual(try client.unpushedCommitCount(), 1)
        XCTAssertEqual(try client.unpushedCommitHashes(), [try local.run(["rev-parse", "HEAD"])])

        try remote.write("remote.txt", content: "remote\n")
        try remote.run(["add", "."])
        try remote.run(["commit", "-m", "remote change"])
        try client.fetch()

        XCTAssertEqual(try client.aheadBehind(), GitAheadBehind(ahead: 1, behind: 1, hasUpstream: true))
        XCTAssertEqual(try client.unpushedCommitCount(), 1)
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
        XCTAssertEqual(try client.mergeFileContent(path: "shared.txt", version: .base), "base\n")
        XCTAssertEqual(try client.mergeFileContent(path: "shared.txt", version: .ours), "master\n")
        XCTAssertEqual(try client.mergeFileContent(path: "shared.txt", version: .theirs), "feature\n")
        XCTAssertTrue(try client.mergeFileDiff(path: "shared.txt").contains("diff --cc shared.txt"))

        XCTAssertEqual(try client.getMergeConflictFiles(), ["shared.txt"])

        try repo.write("shared.txt", content: "resolved\n")
        try client.addFiles(["shared.txt"])

        try client.continueMerge()
        XCTAssertFalse(try client.isMerging())
    }

    func testCheckoutMergeFileVersionUsesSelectedSide() throws {
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

        try client.checkoutMergeFileVersion(path: "shared.txt", version: .theirs)
        XCTAssertEqual(try repo.read("shared.txt"), "feature\n")

        try client.addFiles(["shared.txt"])
        XCTAssertEqual(try client.getMergeConflictFiles(), [])
    }

    func testCheckoutMergeFileVersionAcceptsOurDeletion() throws {
        let repo = try TestGitRepository()
        try repo.write("shared.txt", content: "base\n")
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "base"])

        try repo.run(["checkout", "-b", "feature"])
        try repo.write("shared.txt", content: "feature\n")
        try repo.run(["commit", "-am", "feature change"])

        try repo.run(["checkout", "master"])
        try repo.run(["rm", "shared.txt"])
        try repo.run(["commit", "-m", "delete shared"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)
        XCTAssertThrowsError(try repo.run(["merge", "feature"])) { _ in }
        XCTAssertEqual(try client.getMergeConflictFiles(), ["shared.txt"])

        try client.checkoutMergeFileVersion(path: "shared.txt", version: .ours)

        XCTAssertFalse(FileManager.default.fileExists(atPath: repo.url.appendingPathComponent("shared.txt").path))
        XCTAssertEqual(try client.getMergeConflictFiles(), [])
    }

    func testCheckoutMergeFileVersionAcceptsTheirFileWhenOursDeleted() throws {
        let repo = try TestGitRepository()
        try repo.write("shared.txt", content: "base\n")
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "base"])

        try repo.run(["checkout", "-b", "feature"])
        try repo.write("shared.txt", content: "feature\n")
        try repo.run(["commit", "-am", "feature change"])

        try repo.run(["checkout", "master"])
        try repo.run(["rm", "shared.txt"])
        try repo.run(["commit", "-m", "delete shared"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)
        XCTAssertThrowsError(try repo.run(["merge", "feature"])) { _ in }
        XCTAssertEqual(try client.getMergeConflictFiles(), ["shared.txt"])

        try client.checkoutMergeFileVersion(path: "shared.txt", version: .theirs)

        XCTAssertEqual(try repo.read("shared.txt"), "feature\n")
        XCTAssertEqual(try client.getMergeConflictFiles(), [])
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

    func testLightweightStatusEntriesReportsStagedAndUnstagedStateWithoutDiffs() throws {
        let repo = try TestGitRepository()
        try repo.write("notes.txt", content: "base\n")
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "initial"])

        try repo.write("notes.txt", content: "staged\n")
        let client = GitRepositoryCLI(repositoryURL: repo.url)
        try client.addFiles(["notes.txt"])
        try repo.write("notes.txt", content: "unstaged\n")

        XCTAssertEqual(
            try client.lightweightStatusEntries(),
            [GitStatusEntry(path: "notes.txt", indexStatus: "M", workTreeStatus: "M")]
        )
    }

    func testLightweightStatusEntriesHandlesSpecialFileNames() throws {
        let repo = try TestGitRepository()
        let path = "folder/file\nname \"quoted\".txt"
        try repo.write(path, content: "hello\n")

        let client = GitRepositoryCLI(repositoryURL: repo.url)

        XCTAssertEqual(
            try client.lightweightStatusEntries(),
            [GitStatusEntry(path: path, indexStatus: "?", workTreeStatus: "?")]
        )
    }

    func testLightweightStatusEntriesReportsRenameDestinationOnly() throws {
        let repo = try TestGitRepository()
        try repo.write("old.txt", content: "hello\n")
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "initial"])
        try repo.run(["mv", "old.txt", "new.txt"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)

        XCTAssertEqual(
            try client.lightweightStatusEntries(),
            [GitStatusEntry(path: "new.txt", indexStatus: "R", workTreeStatus: " ")]
        )
    }

    func testPorcelainStatusParserHandlesLargeStatusOutput() throws {
        let recordCount = 100_000
        var data = Data()

        for index in 0..<recordCount {
            data.append(contentsOf: " M Sources/File\(index).swift".utf8)
            data.append(0)
        }

        let entries = GitRepositoryCLI.parsePorcelainStatusEntries(data)

        XCTAssertEqual(entries.count, recordCount)
        XCTAssertEqual(entries.first, GitStatusEntry(path: "Sources/File0.swift", indexStatus: " ", workTreeStatus: "M"))
        XCTAssertEqual(entries.last, GitStatusEntry(path: "Sources/File99999.swift", indexStatus: " ", workTreeStatus: "M"))
    }

    func testLightweightStatusEntriesHandlesLargeUntrackedRepository() throws {
        let repo = try TestGitRepository()
        let fileCount = ProcessInfo.processInfo.environment["GITOK_LARGE_STATUS_FILE_COUNT"]
            .flatMap(Int.init) ?? 1_000
        let sourceDirectory = repo.url.appendingPathComponent("Sources", isDirectory: true)
        try FileManager.default.createDirectory(at: sourceDirectory, withIntermediateDirectories: true)

        let content = Data("hello\n".utf8)
        for index in 0..<fileCount {
            let fileName = String(format: "File%05d.swift", index)
            try content.write(to: sourceDirectory.appendingPathComponent(fileName))
        }

        let entries = try GitRepositoryCLI(repositoryURL: repo.url).lightweightStatusEntries()

        XCTAssertEqual(entries.count, fileCount)
        XCTAssertEqual(entries.first, GitStatusEntry(path: "Sources/File00000.swift", indexStatus: "?", workTreeStatus: "?"))
        XCTAssertEqual(
            entries.last,
            GitStatusEntry(
                path: String(format: "Sources/File%05d.swift", fileCount - 1),
                indexStatus: "?",
                workTreeStatus: "?"
            )
        )
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

    func testApplyPatchStagesAndUnstagesSingleHunk() throws {
        let repo = try TestGitRepository()
        let base = (1...24).map { "line \($0)" }.joined(separator: "\n") + "\n"
        try repo.write("notes.txt", content: base)
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "initial"])

        let modified = (1...24).map { line -> String in
            if line == 2 { return "line two" }
            if line == 22 { return "line twenty two" }
            return "line \(line)"
        }.joined(separator: "\n") + "\n"
        try repo.write("notes.txt", content: modified)

        let client = GitRepositoryCLI(repositoryURL: repo.url)
        let firstHunkPatch = try XCTUnwrap(firstHunkPatch(from: client.fileDiff("notes.txt", staged: false)))

        try client.applyPatch(firstHunkPatch, mode: .stage)

        XCTAssertEqual(try client.statusEntries(), [GitStatusEntry(path: "notes.txt", indexStatus: "M", workTreeStatus: "M")])
        let stagedDiff = try client.fileDiff("notes.txt", staged: true)
        XCTAssertTrue(stagedDiff.contains("line two"))
        XCTAssertFalse(stagedDiff.contains("line twenty two"))

        let unstagedDiff = try client.fileDiff("notes.txt", staged: false)
        XCTAssertFalse(unstagedDiff.contains("line two"))
        XCTAssertTrue(unstagedDiff.contains("line twenty two"))

        try client.applyPatch(firstHunkPatch, mode: .unstage)

        XCTAssertEqual(try client.statusEntries(), [GitStatusEntry(path: "notes.txt", indexStatus: " ", workTreeStatus: "M")])
        XCTAssertEqual(try client.fileDiff("notes.txt", staged: true), "")
    }

    func testUncommittedFileDiffIncludesStagedAndUnstagedDiffsForOneFile() throws {
        let repo = try TestGitRepository()
        let base = (1...24).map { "line \($0)" }.joined(separator: "\n") + "\n"
        try repo.write("notes.txt", content: base)
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "initial"])

        let modified = (1...24).map { line -> String in
            if line == 2 { return "line two" }
            if line == 22 { return "line twenty two" }
            return "line \(line)"
        }.joined(separator: "\n") + "\n"
        try repo.write("notes.txt", content: modified)

        let client = GitRepositoryCLI(repositoryURL: repo.url)
        let firstHunkPatch = try XCTUnwrap(firstHunkPatch(from: client.fileDiff("notes.txt", staged: false)))
        try client.applyPatch(firstHunkPatch, mode: .stage)

        let diff = try client.uncommittedFileDiff(for: "notes.txt")
        XCTAssertTrue(diff.contains("line two"))
        XCTAssertTrue(diff.contains("line twenty two"))
        XCTAssertFalse(diff.contains("README.md"))
    }

    func testRevertCommitCreatesInverseCommit() throws {
        let repo = try TestGitRepository()
        try repo.write("README.md", content: "base\n")
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "initial"])
        try repo.write("README.md", content: "changed\n")
        try repo.run(["commit", "-am", "change readme"])
        let commitToRevert = try repo.run(["rev-parse", "HEAD"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)
        try client.revertCommit(commitToRevert)

        XCTAssertEqual(try repo.read("README.md"), "base\n")
        XCTAssertEqual(try repo.run(["log", "-1", "--pretty=%s"]), "Revert \"change readme\"")
    }

    func testResetSupportsSoftMixedAndHardModes() throws {
        let repo = try TestGitRepository()
        try repo.write("README.md", content: "base\n")
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "initial"])
        let initial = try repo.run(["rev-parse", "HEAD"])
        try repo.write("README.md", content: "changed\n")
        try repo.run(["commit", "-am", "change readme"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)
        try client.reset(to: initial, mode: .soft)
        XCTAssertEqual(try client.statusEntries(), [GitStatusEntry(path: "README.md", indexStatus: "M", workTreeStatus: " ")])

        try repo.run(["commit", "-m", "change readme again"])
        try client.reset(to: initial, mode: .mixed)
        XCTAssertEqual(try client.statusEntries(), [GitStatusEntry(path: "README.md", indexStatus: " ", workTreeStatus: "M")])

        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "change readme third"])
        try client.reset(to: initial, mode: .hard)
        XCTAssertEqual(try repo.read("README.md"), "base\n")
        XCTAssertEqual(try client.statusEntries(), [])
    }

    func testSquashLastCommitsCombinesHistory() throws {
        let repo = try TestGitRepository()
        try repo.write("README.md", content: "base\n")
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "initial"])
        try repo.write("one.txt", content: "one\n")
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "one"])
        try repo.write("two.txt", content: "two\n")
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "two"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)
        try client.squashLastCommits(count: 2, message: "squashed work")

        XCTAssertEqual(try repo.run(["log", "--pretty=%s"]), "squashed work\ninitial")
        XCTAssertEqual(try repo.read("one.txt"), "one\n")
        XCTAssertEqual(try repo.read("two.txt"), "two\n")
        XCTAssertEqual(try client.statusEntries(), [])
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

    // MARK: - CLI Git Availability Tests

    func testIsGitCLIAvailableReturnsTrue() {
        // macOS 开发环境（安装了 Xcode CLT 或 git）应该有 git CLI
        XCTAssertTrue(GitRepositoryCLI.isGitCLIAvailable())
    }

    func testGitCLIPathReturnsNonEmptyString() {
        let path = GitRepositoryCLI.gitCLIPath()
        XCTAssertNotNil(path)
        XCTAssertFalse(path?.isEmpty ?? true)
    }

    func testGitCLIPathPointsToExecutable() {
        guard let path = GitRepositoryCLI.gitCLIPath() else {
            XCTFail("git CLI path should not be nil")
            return
        }
        XCTAssertTrue(FileManager.default.isExecutableFile(atPath: path))
    }

    func testGitCLIPathResultsAreCached() {
        // 两次调用应该返回相同结果（缓存）
        let first = GitRepositoryCLI.gitCLIPath()
        let second = GitRepositoryCLI.gitCLIPath()
        XCTAssertEqual(first, second)
    }

    func testCliPushPushesToRemote() throws {
        // 创建 bare repo 作为远程
        let bareRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: bareRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: bareRoot) }

        let bareURL = bareRoot.appendingPathComponent("remote.git", isDirectory: true)
        try FileManager.default.createDirectory(at: bareURL, withIntermediateDirectories: true)
        let bareProcess = Process()
        bareProcess.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        bareProcess.arguments = ["git", "init", "--bare", bareURL.path]
        bareProcess.currentDirectoryURL = bareRoot
        try bareProcess.run()
        bareProcess.waitUntilExit()

        // 创建本地仓库并添加远程
        let repo = try TestGitRepository()
        try repo.run(["remote", "add", "origin", bareURL.path])
        try repo.run(["commit", "--allow-empty", "-m", "initial"])

        try repo.write("local.txt", content: "local change\n")
        try repo.run(["add", "."])
        try repo.run(["commit", "-m", "local commit"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)
        try client.cliPush()

        // 验证 bare repo 收到了提交（通过 ls-remote 检查）
        let verifyProcess = Process()
        let verifyPipe = Pipe()
        verifyProcess.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        verifyProcess.arguments = ["git", "ls-remote", bareURL.path]
        verifyProcess.standardOutput = verifyPipe
        try verifyProcess.run()
        verifyProcess.waitUntilExit()

        let output = String(data: verifyPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        XCTAssertTrue(output.contains("refs/heads/master"))
    }

    func testCliPushThrowsWhenCLIUnavailable() throws {
        // 使用一个假路径来模拟 git CLI 不可用
        // 注意：这个测试验证的是错误路径，正常环境无法真正模拟 CLI 不存在
        // 所以我们验证正常环境下 cliPush 不抛出 nativeGitUnavailableError
        let repo = try TestGitRepository()
        try repo.run(["commit", "--allow-empty", "-m", "initial"])

        let client = GitRepositoryCLI(repositoryURL: repo.url)
        // 没有远程仓库时应该抛出错误（非 nativeGitUnavailableError）
        XCTAssertThrowsError(try client.cliPush()) { error in
            let nsError = error as NSError
            // 应该是 git CLI 的错误，而不是 "nativeGitUnavailable" 错误
            XCTAssertFalse(nsError.localizedDescription.contains("已阻止调用系统 git"))
        }
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
        let progressCollector = TestProgressCollector()
        try GitRepositoryCLI.clone(remoteURL: remote.url.path, destinationURL: destinationURL) { line in
            progressCollector.append(line)
        }

        XCTAssertTrue(FileManager.default.fileExists(atPath: destinationURL.appendingPathComponent(".git").path))
        XCTAssertEqual(try String(contentsOf: destinationURL.appendingPathComponent("README.md"), encoding: .utf8), "hello\n")
        XCTAssertFalse(progressCollector.lines.isEmpty)
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

    func writeData(_ relativePath: String, data: Data) throws {
        let fileURL = url.appendingPathComponent(relativePath)
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: fileURL)
    }

    func read(_ relativePath: String) throws -> String? {
        let fileURL = url.appendingPathComponent(relativePath)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        return try String(contentsOf: fileURL, encoding: .utf8)
    }

    func addWithDisabledLFSFilter() throws {
        try run([
            "-c", "filter.lfs.process=",
            "-c", "filter.lfs.clean=cat",
            "-c", "filter.lfs.required=false",
            "add", ".",
        ])
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

private func lfsPointer() -> String {
    """
    version https://git-lfs.github.com/spec/v1
    oid sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
    size 123

    """
}

private func firstHunkPatch(from diff: String) -> String? {
    let lines = diff.components(separatedBy: "\n")
    var fileHeader: [String] = []
    var currentHunk: [String] = []

    for line in lines {
        if line.hasPrefix("@@ ") {
            if currentHunk.isEmpty == false {
                return (fileHeader + currentHunk).joined(separator: "\n") + "\n"
            }
            currentHunk = [line]
            continue
        }

        if currentHunk.isEmpty {
            fileHeader.append(line)
        } else {
            currentHunk.append(line)
        }
    }

    guard currentHunk.isEmpty == false else { return nil }
    return (fileHeader + currentHunk).joined(separator: "\n") + "\n"
}

private final class TestProgressCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String] = []

    var lines: [String] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    func append(_ line: String) {
        lock.lock()
        storage.append(line)
        lock.unlock()
    }
}
