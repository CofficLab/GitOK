import Foundation
import XCTest
@testable import KitGit

// MARK: - CommitGraphLayoutRules（纯算法）

final class CommitGraphLayoutRulesTests: XCTestCase {

    private func node(_ id: String, parents: [String] = []) -> CommitGraphLayoutRules.Node {
        CommitGraphLayoutRules.Node(id: id, parentIDs: parents)
    }

    func testSingleCommitGetsLaneZero() {
        let rows = CommitGraphLayoutRules.layout(nodes: [node("A")])

        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].commitID, "A")
        XCTAssertEqual(rows[0].nodeLane, 0)
        XCTAssertEqual(rows[0].topSegments, [])
        XCTAssertEqual(rows[0].bottomSegments, [])
        XCTAssertEqual(rows[0].parentEdges, [])
        XCTAssertEqual(rows[0].laneCount, 1)
    }

    func testLinearChainSharesOneLane() {
        // 新→旧：C → B → A
        let rows = CommitGraphLayoutRules.layout(nodes: [
            node("C", parents: ["B"]),
            node("B", parents: ["A"]),
            node("A"),
        ])

        XCTAssertEqual(rows.map(\.nodeLane), [0, 0, 0])
        // 首行没有上游 lane；后续行把自身带进 topSegments。
        XCTAssertEqual(rows[0].topSegments, [])
        XCTAssertEqual(rows[1].topSegments, [.init(lane: 0, id: "B")])
        XCTAssertEqual(rows[0].bottomSegments, [.init(lane: 0, id: "B")])
        XCTAssertEqual(rows[0].parentEdges, [.init(parentID: "B", fromLane: 0, toLane: 0)])
        XCTAssertEqual(rows[1].parentEdges, [.init(parentID: "A", fromLane: 0, toLane: 0)])
    }

    func testForkCreatesNewLane() {
        // E → C、D（都来自 B）：C、D 各占一个 lane，E 在其上合并。
        let rows = CommitGraphLayoutRules.layout(nodes: [
            node("E", parents: ["C", "D"]),
            node("D", parents: ["B"]),
            node("C", parents: ["B"]),
            node("B", parents: ["A"]),
            node("A"),
        ])

        let nodeLanes = rows.map(\.nodeLane)
        XCTAssertEqual(nodeLanes, [0, 1, 0, 0, 0])
        XCTAssertEqual(rows[0].laneCount, 2)
        XCTAssertEqual(rows[0].parentEdges.count, 2)
    }

    func testMergeReusesLane() {
        // 合并后 lane 收敛：D(merge) → C、B → A
        let rows = CommitGraphLayoutRules.layout(nodes: [
            node("D", parents: ["C", "B"]),
            node("C", parents: ["A"]),
            node("B", parents: ["A"]),
            node("A"),
        ])

        let nodeLanes = rows.map(\.nodeLane)
        XCTAssertEqual(nodeLanes, [0, 0, 1, 0])
        // merge 行两条 parent 边，指向两个不同 lane。
        XCTAssertEqual(rows[0].parentEdges.count, 2)
    }

    func testSelfParentExcluded() {
        // parent 指向自身（异常数据）应被忽略，不产生边。
        let rows = CommitGraphLayoutRules.layout(nodes: [
            node("A", parents: ["A"]),
        ])

        XCTAssertEqual(rows[0].parentEdges, [])
        XCTAssertEqual(rows[0].bottomSegments, [])
    }

    func testDuplicateParentsDeduplicated() {
        let rows = CommitGraphLayoutRules.layout(nodes: [
            node("C", parents: ["B", "B"]),
            node("B", parents: ["A"]),
            node("A"),
        ])

        XCTAssertEqual(rows[0].parentEdges.count, 1)
    }

    func testLaneCountAccountsForAllSegments() {
        let rows = CommitGraphLayoutRules.layout(nodes: [
            node("D", parents: ["B", "C"]),
            node("C", parents: ["A"]),
            node("B", parents: ["A"]),
            node("A"),
        ])
        // D 行有两个 parent lane（自身 lane 已释放）。
        XCTAssertEqual(rows[0].laneCount, 2)
    }
}

// MARK: - GitRefReader

final class GitRefReaderTests: XCTestCase {

    private func makeRepo() throws -> URL {
        let repo = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-refreader-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: repo, withIntermediateDirectories: true)
        _ = try runGit(["init", "-q"], in: repo)
        _ = try runGit(["config", "user.email", "t@t.com"], in: repo)
        _ = try runGit(["config", "user.name", "t"], in: repo)
        _ = try runGit(["checkout", "-q", "-b", "main"], in: repo)
        try Data("initial\n".utf8).write(to: repo.appendingPathComponent("README.md"))
        try GitCommitOperation.addAll(in: repo)
        try GitCommitOperation.commit(message: "initial", in: repo)
        return repo
    }

    private func runGit(_ arguments: [String], in directory: URL) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments
        process.currentDirectoryURL = directory
        let output = Pipe()
        let error = Pipe()
        process.standardOutput = output
        process.standardError = error
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let message = String(data: error.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "git failed"
            throw NSError(domain: "GitRefReaderTests", code: Int(process.terminationStatus), userInfo: [
                NSLocalizedDescriptionKey: message
            ])
        }
        return String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    }

    func testCurrentBranchAndDetachedHead() throws {
        let repo = try makeRepo()
        defer { try? FileManager.default.removeItem(at: repo) }

        XCTAssertEqual(GitRefReader.currentBranch(in: repo), "main")

        let headHash = try GitProcessRunner.run(["rev-parse", "HEAD"], in: repo)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        _ = try runGit(["checkout", "-q", headHash], in: repo)
        XCTAssertNil(GitRefReader.currentBranch(in: repo))
    }

    func testHasRemotes() throws {
        let repo = try makeRepo()
        defer { try? FileManager.default.removeItem(at: repo) }

        XCTAssertFalse(GitRefReader.hasRemotes(in: repo))

        _ = try runGit(["remote", "add", "origin", "https://example.com/repo.git"], in: repo)
        XCTAssertTrue(GitRefReader.hasRemotes(in: repo))
    }

    func testUnpushedCountWithAndWithoutUpstream() throws {
        let repo = try makeRepo()
        let remote = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-refremote-\(UUID().uuidString).git")
        defer {
            try? FileManager.default.removeItem(at: repo)
            try? FileManager.default.removeItem(at: remote)
        }
        _ = try runGit(["init", "--bare", "-q", remote.path], in: FileManager.default.temporaryDirectory)
        _ = try runGit(["remote", "add", "origin", remote.path], in: repo)
        _ = try runGit(["push", "-q", "-u", "origin", "main"], in: repo)

        // 有上游、已同步 → 0
        XCTAssertEqual(GitRefReader.unpushedCount(in: repo), 0)

        // 再提交一个 → 1
        try Data("second\n".utf8).write(to: repo.appendingPathComponent("b.txt"))
        try GitCommitOperation.addAll(in: repo)
        try GitCommitOperation.commit(message: "second", in: repo)
        XCTAssertEqual(GitRefReader.unpushedCount(in: repo), 1)
    }

    func testUnpushedCountWithoutUpstreamIsNil() throws {
        let repo = try makeRepo()
        defer { try? FileManager.default.removeItem(at: repo) }

        XCTAssertNil(GitRefReader.unpushedCount(in: repo))
    }

    func testRemoteTrackingStatus() throws {
        let repo = try makeRepo()
        let remote = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-refstatus-\(UUID().uuidString).git")
        defer {
            try? FileManager.default.removeItem(at: repo)
            try? FileManager.default.removeItem(at: remote)
        }
        // 无上游
        XCTAssertEqual(
            GitRefReader.remoteTrackingStatus(in: repo),
            .init(ahead: 0, behind: 0, hasUpstream: false)
        )

        _ = try runGit(["init", "--bare", "-q", remote.path], in: FileManager.default.temporaryDirectory)
        _ = try runGit(["remote", "add", "origin", remote.path], in: repo)
        _ = try runGit(["push", "-q", "-u", "origin", "main"], in: repo)
        XCTAssertEqual(
            GitRefReader.remoteTrackingStatus(in: repo),
            .init(ahead: 0, behind: 0, hasUpstream: true)
        )

        try Data("more\n".utf8).write(to: repo.appendingPathComponent("c.txt"))
        try GitCommitOperation.addAll(in: repo)
        try GitCommitOperation.commit(message: "more", in: repo)
        XCTAssertEqual(
            GitRefReader.remoteTrackingStatus(in: repo),
            .init(ahead: 1, behind: 0, hasUpstream: true)
        )
    }

    func testUnpulledCountAfterFetch() throws {
        let origin = try makeRepo()
        let clone = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-refclone-\(UUID().uuidString)")
        defer {
            try? FileManager.default.removeItem(at: origin)
            try? FileManager.default.removeItem(at: clone)
        }
        _ = try runGit(["clone", "-q", origin.path, clone.path], in: FileManager.default.temporaryDirectory)
        XCTAssertEqual(GitRefReader.unpulledCount(in: clone), 0)

        try Data("upstream\n".utf8).write(to: origin.appendingPathComponent("d.txt"))
        try GitCommitOperation.addAll(in: origin)
        try GitCommitOperation.commit(message: "upstream", in: origin)

        _ = try runGit(["fetch", "-q"], in: clone)
        XCTAssertEqual(GitRefReader.unpulledCount(in: clone), 1)
    }
}

// MARK: - GitRemoteOperation

final class GitRemoteOperationTests: XCTestCase {

    private func makeRepo() throws -> URL {
        let repo = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-remoteop-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: repo, withIntermediateDirectories: true)
        _ = try runGit(["init", "-q"], in: repo)
        _ = try runGit(["config", "user.email", "t@t.com"], in: repo)
        _ = try runGit(["config", "user.name", "t"], in: repo)
        _ = try runGit(["checkout", "-q", "-b", "main"], in: repo)
        try Data("initial\n".utf8).write(to: repo.appendingPathComponent("README.md"))
        try GitCommitOperation.addAll(in: repo)
        try GitCommitOperation.commit(message: "initial", in: repo)
        return repo
    }

    private func runGit(_ arguments: [String], in directory: URL) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments
        process.currentDirectoryURL = directory
        let output = Pipe()
        let error = Pipe()
        process.standardOutput = output
        process.standardError = error
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let message = String(data: error.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "git failed"
            throw NSError(domain: "GitRemoteOperationTests", code: Int(process.terminationStatus), userInfo: [
                NSLocalizedDescriptionKey: message
            ])
        }
        return String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    }

    func testWebLinkParsing() {
        XCTAssertEqual(
            GitRemoteOperation.webLink(for: "https://github.com/owner/repo.git")?.absoluteString,
            "https://github.com/owner/repo.git"
        )
        XCTAssertEqual(
            GitRemoteOperation.webLink(for: "http://host/repo")?.absoluteString,
            "http://host/repo"
        )
        // SSH 简写 git@host:owner/repo.git
        XCTAssertEqual(
            GitRemoteOperation.webLink(for: "git@github.com:owner/repo.git")?.absoluteString,
            "https://github.com/owner/repo"
        )
        XCTAssertEqual(
            GitRemoteOperation.webLink(for: "git@github.com:owner/repo")?.absoluteString,
            "https://github.com/owner/repo"
        )
        // ssh:// 形式
        XCTAssertEqual(
            GitRemoteOperation.webLink(for: "ssh://git@github.com/owner/repo.git")?.absoluteString,
            "https://github.com/owner/repo"
        )
        // 无法解析
        XCTAssertNil(GitRemoteOperation.webLink(for: "not-a-url"))
    }

    func testAddRemoveAndListRemotes() throws {
        let repo = try makeRepo()
        defer { try? FileManager.default.removeItem(at: repo) }

        try GitRemoteOperation.addRemote(name: "origin", url: "https://example.com/a.git", in: repo)
        try GitRemoteOperation.addRemote(name: "backup", url: "git@example.com:b/c.git", in: repo)

        let remotes = GitRemoteOperation.listRemotes(in: repo)
        XCTAssertEqual(remotes.map(\.name).sorted(), ["backup", "origin"])
        // 每个远程都解析出 fetchURL 与 pushURL（git remote -v 的 (fetch)/(push) 行）。
        for remote in remotes {
            XCTAssertNotNil(remote.fetchURL, "remote=\(remote.name)")
            XCTAssertNotNil(remote.pushURL, "remote=\(remote.name)")
            XCTAssertEqual(remote.url, remote.fetchURL)
        }

        try GitRemoteOperation.removeRemote(name: "backup", in: repo)
        XCTAssertEqual(GitRemoteOperation.listRemotes(in: repo).map(\.name), ["origin"])
    }

    func testPushFetchRoundTrip() throws {
        let origin = try makeRepo()
        let clone = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-remoteclone-\(UUID().uuidString)")
        defer {
            try? FileManager.default.removeItem(at: origin)
            try? FileManager.default.removeItem(at: clone)
        }
        _ = try runGit(["clone", "-q", origin.path, clone.path], in: FileManager.default.temporaryDirectory)
        // 允许推送到非 bare 仓库的当前分支。
        _ = try runGit(["config", "receive.denyCurrentBranch", "ignore"], in: origin)

        // 1) 本地提交 → push（fast-forward）。
        try Data("local-change\n".utf8).write(to: clone.appendingPathComponent("f.txt"))
        try GitCommitOperation.addAll(in: clone)
        try GitCommitOperation.commit(message: "local-change", in: clone)
        try GitRemoteOperation.push(in: clone)
        let originHead = try runGit(["rev-parse", "main"], in: origin)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let cloneHead = try GitProcessRunner.run(["rev-parse", "HEAD"], in: clone)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertEqual(originHead, cloneHead)

        // 2) 远端新增提交 → fetch 拉取到 FETCH_HEAD。
        try Data("remote-change\n".utf8).write(to: origin.appendingPathComponent("e.txt"))
        try GitCommitOperation.addAll(in: origin)
        try GitCommitOperation.commit(message: "remote-change", in: origin)

        let before = cloneHead
        try GitRemoteOperation.fetch(in: clone)
        let afterFetch = try GitProcessRunner.run(["rev-parse", "FETCH_HEAD"], in: clone)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertNotEqual(before, afterFetch)
    }

    func testSynchronizeFastForwardsRemoteOnlyChanges() throws {
        let origin = try makeRepo()
        let clone = try makeClone(of: origin)
        defer {
            try? FileManager.default.removeItem(at: origin)
            try? FileManager.default.removeItem(at: clone)
        }

        try Data("remote-change\n".utf8).write(to: origin.appendingPathComponent("remote.txt"))
        try GitCommitOperation.addAll(in: origin)
        try GitCommitOperation.commit(message: "remote-change", in: origin)

        let status = try GitRemoteOperation.synchronize(in: clone)

        XCTAssertEqual(status, .init(ahead: 0, behind: 0, hasUpstream: true))
        XCTAssertEqual(
            try runGit(["rev-parse", "HEAD"], in: clone).trimmingCharacters(in: .whitespacesAndNewlines),
            try runGit(["rev-parse", "main"], in: origin).trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    func testSynchronizePushesLocalOnlyChanges() throws {
        let origin = try makeRepo()
        let clone = try makeClone(of: origin)
        defer {
            try? FileManager.default.removeItem(at: origin)
            try? FileManager.default.removeItem(at: clone)
        }

        try Data("local-change\n".utf8).write(to: clone.appendingPathComponent("local.txt"))
        try GitCommitOperation.addAll(in: clone)
        try GitCommitOperation.commit(message: "local-change", in: clone)

        let status = try GitRemoteOperation.synchronize(in: clone)

        XCTAssertEqual(status, .init(ahead: 0, behind: 0, hasUpstream: true))
        XCTAssertEqual(
            try runGit(["rev-parse", "HEAD"], in: clone).trimmingCharacters(in: .whitespacesAndNewlines),
            try runGit(["rev-parse", "main"], in: origin).trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    func testSynchronizeMergesDivergedChangesThenPushes() throws {
        let origin = try makeRepo()
        let clone = try makeClone(of: origin)
        defer {
            try? FileManager.default.removeItem(at: origin)
            try? FileManager.default.removeItem(at: clone)
        }

        try Data("remote-change\n".utf8).write(to: origin.appendingPathComponent("remote.txt"))
        try GitCommitOperation.addAll(in: origin)
        try GitCommitOperation.commit(message: "remote-change", in: origin)

        try Data("local-change\n".utf8).write(to: clone.appendingPathComponent("local.txt"))
        try GitCommitOperation.addAll(in: clone)
        try GitCommitOperation.commit(message: "local-change", in: clone)

        let status = try GitRemoteOperation.synchronize(in: clone)

        XCTAssertEqual(status, .init(ahead: 0, behind: 0, hasUpstream: true))
        XCTAssertTrue(FileManager.default.fileExists(atPath: clone.appendingPathComponent("remote.txt").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: clone.appendingPathComponent("local.txt").path))
        XCTAssertEqual(
            try runGit(["rev-parse", "HEAD"], in: clone).trimmingCharacters(in: .whitespacesAndNewlines),
            try runGit(["rev-parse", "main"], in: origin).trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    func testSynchronizeReportsMergeConflictAndLeavesOperationOpen() throws {
        let origin = try makeRepo()
        let clone = try makeClone(of: origin)
        defer {
            try? FileManager.default.removeItem(at: origin)
            try? FileManager.default.removeItem(at: clone)
        }

        try Data("remote-change\n".utf8).write(to: origin.appendingPathComponent("README.md"))
        try GitCommitOperation.addAll(in: origin)
        try GitCommitOperation.commit(message: "remote-change", in: origin)

        try Data("local-change\n".utf8).write(to: clone.appendingPathComponent("README.md"))
        try GitCommitOperation.addAll(in: clone)
        try GitCommitOperation.commit(message: "local-change", in: clone)

        do {
            _ = try GitRemoteOperation.synchronize(in: clone)
            XCTFail("expected merge conflict")
        } catch let error as GitRemoteOperation.SyncError {
            if case .merge = error.step {
                XCTAssertTrue(GitMergeOperation.isMerging(in: clone))
            } else {
                XCTFail("expected merge step, got \(error.step)")
            }
        }

        _ = try GitMergeOperation.abortMerge(in: clone)
    }

    private func makeClone(of origin: URL) throws -> URL {
        let clone = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-remoteclone-\(UUID().uuidString)")
        _ = try runGit(["clone", "-q", origin.path, clone.path], in: FileManager.default.temporaryDirectory)
        _ = try runGit(["config", "receive.denyCurrentBranch", "ignore"], in: origin)
        return clone
    }
}

// MARK: - GitStashOperation

final class GitStashOperationTests: XCTestCase {

    private func makeRepo() throws -> URL {
        let repo = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-stash-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: repo, withIntermediateDirectories: true)
        _ = try runGit(["init", "-q"], in: repo)
        _ = try runGit(["config", "user.email", "t@t.com"], in: repo)
        _ = try runGit(["config", "user.name", "t"], in: repo)
        _ = try runGit(["checkout", "-q", "-b", "main"], in: repo)
        try Data("initial\n".utf8).write(to: repo.appendingPathComponent("README.md"))
        try GitCommitOperation.addAll(in: repo)
        try GitCommitOperation.commit(message: "initial", in: repo)
        return repo
    }

    private func runGit(_ arguments: [String], in directory: URL) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments
        process.currentDirectoryURL = directory
        let output = Pipe()
        let error = Pipe()
        process.standardOutput = output
        process.standardError = error
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let message = String(data: error.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "git failed"
            throw NSError(domain: "GitStashOperationTests", code: Int(process.terminationStatus), userInfo: [
                NSLocalizedDescriptionKey: message
            ])
        }
        return String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    }

    private func dirty(repo: URL) throws {
        try Data("dirty\n".utf8).write(to: repo.appendingPathComponent("README.md"))
    }

    func testSaveListApply() throws {
        let repo = try makeRepo()
        defer { try? FileManager.default.removeItem(at: repo) }

        XCTAssertFalse(GitStashOperation.hasChanges(in: repo))
        try dirty(repo: repo)
        XCTAssertTrue(GitStashOperation.hasChanges(in: repo))

        try GitStashOperation.save(message: "wip work", in: repo)
        let entries = GitStashOperation.list(in: repo)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].index, 0)
        // 列表解析保留 "WIP on <branch>: " 前缀中的分支名。
        XCTAssertEqual(entries[0].message, "main: wip work")
        // 工作区已恢复干净
        XCTAssertFalse(GitStashOperation.hasChanges(in: repo))

        // apply：恢复改动但不删除条目
        try GitStashOperation.apply(entries[0], in: repo)
        XCTAssertTrue(GitStashOperation.hasChanges(in: repo))
        XCTAssertEqual(GitStashOperation.list(in: repo).count, 1)

        // 丢弃工作区改动，避免干扰后续
        _ = try runGit(["checkout", "-q", "--", "."], in: repo)
        XCTAssertFalse(GitStashOperation.hasChanges(in: repo))
    }

    func testPopRestoresAndRemoves() throws {
        let repo = try makeRepo()
        defer { try? FileManager.default.removeItem(at: repo) }
        try dirty(repo: repo)

        try GitStashOperation.save(message: "pop me", in: repo)
        let entry = try XCTUnwrap(GitStashOperation.list(in: repo).first)

        try GitStashOperation.pop(entry, in: repo)

        // 改动恢复、条目删除
        XCTAssertTrue(GitStashOperation.hasChanges(in: repo))
        XCTAssertEqual(GitStashOperation.list(in: repo).count, 0)
    }

    func testSaveWithoutMessageListsWIPDescription() throws {
        let repo = try makeRepo()
        defer { try? FileManager.default.removeItem(at: repo) }
        try dirty(repo: repo)

        try GitStashOperation.save(message: nil, in: repo)

        let entries = GitStashOperation.list(in: repo)
        XCTAssertEqual(entries.count, 1)
        // 无消息时保留 "WIP on <branch>: <sha> <subject>" 的分支前缀，sha 随机。
        XCTAssertTrue(entries[0].message.hasPrefix("main: "), "actual=\(entries[0].message)")
        XCTAssertTrue(entries[0].message.count > "main: ".count)
    }

    func testDropRemovesEntry() throws {
        let repo = try makeRepo()
        defer { try? FileManager.default.removeItem(at: repo) }
        try dirty(repo: repo)
        try GitStashOperation.save(message: "keep", in: repo)

        let entry = try XCTUnwrap(GitStashOperation.list(in: repo).first)
        try GitStashOperation.drop(entry, in: repo)

        XCTAssertEqual(GitStashOperation.list(in: repo).count, 0)
    }
}

// MARK: - GitConfigReader

final class GitConfigReaderTests: XCTestCase {

    private func makeRepo() throws -> URL {
        let repo = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-config-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: repo, withIntermediateDirectories: true)
        _ = try ProcessRunner.runGit(["init", "-q"], in: repo)
        return repo
    }

    func testValueRoundTripAndUser() throws {
        let repo = try makeRepo()
        defer { try? FileManager.default.removeItem(at: repo) }

        // 随机 key：全局配置不可能存在，初始必为 nil。
        let uniqueKey = "test.unique.\(UUID().uuidString)"
        XCTAssertNil(GitConfigReader.value(uniqueKey, in: repo))

        // 仓库级配置覆盖全局配置。
        try GitConfigReader.setValue("user.email", "me@example.com", in: repo)
        XCTAssertEqual(GitConfigReader.value("user.email", in: repo), "me@example.com")

        try GitConfigReader.setValue("user.name", "Tester", in: repo)
        let user = GitConfigReader.user(in: repo)
        XCTAssertEqual(user.name, "Tester")
        XCTAssertEqual(user.email, "me@example.com")
    }

    func testMissingKeyReturnsNil() throws {
        let repo = try makeRepo()
        defer { try? FileManager.default.removeItem(at: repo) }

        XCTAssertNil(GitConfigReader.value("nonexistent.\(UUID().uuidString)", in: repo))
    }
}

private enum ProcessRunner {
    static func runGit(_ arguments: [String], in directory: URL) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments
        process.currentDirectoryURL = directory
        let output = Pipe()
        let error = Pipe()
        process.standardOutput = output
        process.standardError = error
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let message = String(data: error.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "git failed"
            throw NSError(domain: "GitConfigReaderTests", code: Int(process.terminationStatus), userInfo: [
                NSLocalizedDescriptionKey: message
            ])
        }
        return String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    }
}
