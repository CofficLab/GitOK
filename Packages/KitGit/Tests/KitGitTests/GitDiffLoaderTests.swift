import Foundation
import XCTest
@testable import KitGit

final class GitDiffLoaderTests: XCTestCase {
    /// 当前仓库根（GitOK 自身）：由测试文件位置推导，避免硬编码他人机器路径。
    private var selfRepoURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // GitDiffLoaderTests.swift
            .deletingLastPathComponent() // KitGitTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // KitGit
            .deletingLastPathComponent() // Packages
    }

    /// 在当前仓库根（GitOK 自身）上做只读冒烟测试。
    func testLoadChangesOnSelf() throws {
        let repo = selfRepoURL
        guard FileManager.default.fileExists(atPath: repo.appendingPathComponent(".git").path) else {
            throw XCTSkip("not inside a GitOK git checkout: \(repo.path)")
        }
        let commits = try GitCommitLoader.loadCommits(in: repo, limit: 5)
        guard let head = commits.first else {
            throw XCTSkip("no commits in self repo")
        }
        let changes = try GitDiffLoader.loadChanges(commit: head.hash, in: repo)
        XCTAssertFalse(changes.isEmpty)
        XCTAssertTrue(changes.allSatisfy { !$0.path.isEmpty })
    }

    func testCancellableDiffReadsHonorPreCancelledRequests() {
        let repository = URL(fileURLWithPath: "/missing/repository")
        let cancellation = GitProcessCancellation()
        cancellation.cancel()

        XCTAssertThrowsError(
            try GitDiffLoader.countChanges(
                commit: "HEAD",
                in: repository,
                cancellation: cancellation
            )
        ) { XCTAssertTrue($0 is CancellationError) }
        XCTAssertThrowsError(
            try GitDiffLoader.loadChangesPage(
                commit: "HEAD",
                limit: 100,
                offset: 0,
                in: repository,
                cancellation: cancellation
            )
        ) { XCTAssertTrue($0 is CancellationError) }
        XCTAssertThrowsError(
            try GitDiffLoader.loadDiff(
                commit: "HEAD",
                filePath: "file.txt",
                in: repository,
                cancellation: cancellation
            )
        ) { XCTAssertTrue($0 is CancellationError) }
        XCTAssertThrowsError(
            try GitDiffLoader.loadWorktreeDiff(
                filePath: "file.txt",
                in: repository,
                cancellation: cancellation
            )
        ) { XCTAssertTrue($0 is CancellationError) }
    }

    func testLoadChangesPageMatchesEagerCompatibilityAPI() throws {
        let repo = selfRepoURL
        guard FileManager.default.fileExists(atPath: repo.appendingPathComponent(".git").path) else {
            throw XCTSkip("not inside a GitOK git checkout: \(repo.path)")
        }
        let commits = try GitCommitLoader.loadCommits(in: repo, limit: 5)
        guard let head = commits.first else {
            throw XCTSkip("no commits in self repo")
        }

        let allChanges = try GitDiffLoader.loadChanges(commit: head.hash, in: repo)
        let total = try GitDiffLoader.countChanges(commit: head.hash, in: repo)
        XCTAssertEqual(total, allChanges.count)

        let firstPage = try GitDiffLoader.loadChangesPage(
            commit: head.hash,
            limit: 1,
            offset: 0,
            in: repo
        )
        XCTAssertEqual(firstPage.changes, Array(allChanges.prefix(1)))
        XCTAssertEqual(firstPage.hasMore, allChanges.count > 1)

        if allChanges.count > 1 {
            let secondPage = try GitDiffLoader.loadChangesPage(
                commit: head.hash,
                limit: 1,
                offset: 1,
                in: repo
            )
            XCTAssertEqual(secondPage.changes, [allChanges[1]])
        }
    }

    func testLoadChangesPagePreservesRenames() throws {
        let repo = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-rename-(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: repo) }
        try FileManager.default.createDirectory(at: repo, withIntermediateDirectories: true)

        func run(_ args: [String]) throws {
            _ = try GitProcessRunner.run(args, in: repo)
        }

        try run(["init", "-q"])
        try run(["config", "user.email", "t@t.com"])
        try run(["config", "user.name", "t"])
        try Data("one\ntwo\nthree\n".utf8).write(to: repo.appendingPathComponent("old.txt"))
        try run(["add", "old.txt"])
        try run(["commit", "-qm", "init"])
        try run(["mv", "old.txt", "new.txt"])
        try run(["commit", "-qam", "rename"])
        let renameHash = try runAndRead(["rev-parse", "HEAD"], in: repo)

        let page = try GitDiffLoader.loadChangesPage(
            commit: renameHash,
            limit: 10,
            offset: 0,
            in: repo
        )
        XCTAssertEqual(page.changes.count, 1)
        XCTAssertEqual(page.changes.first?.status, .renamed)
        XCTAssertEqual(page.changes.first?.oldPath, "old.txt")
        XCTAssertEqual(page.changes.first?.path, "new.txt")
    }

    func testLoadChangesPageHandlesLargeCommitWithoutEagerOutputParsing() throws {
        let repo = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-large-diff-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: repo) }
        let filesDirectory = repo.appendingPathComponent("files", isDirectory: true)
        try FileManager.default.createDirectory(at: filesDirectory, withIntermediateDirectories: true)

        func run(_ args: [String]) throws {
            _ = try GitProcessRunner.run(args, in: repo)
        }

        try run(["init", "-q"])
        try run(["config", "user.email", "t@t.com"])
        try run(["config", "user.name", "t"])
        for index in 0..<1_000 {
            let file = filesDirectory.appendingPathComponent("file-\(index).txt")
            try Data("file \(index)\n".utf8).write(to: file)
        }
        try run(["add", "files"])
        try run(["commit", "-qm", "large change"])
        let hash = try runAndRead(["rev-parse", "HEAD"], in: repo)

        XCTAssertEqual(try GitDiffLoader.countChanges(commit: hash, in: repo), 1_000)
        // git 按字典序输出路径（file-1, file-10, file-100, ...），因此「第 900 条
        // 记录」并不等于 file-900.txt；以字典序排序后的真实路径列表为准。
        let sortedPaths = (0..<1_000).map { "files/file-\($0).txt" }.sorted()
        let page = try GitDiffLoader.loadChangesPage(
            commit: hash,
            limit: 100,
            offset: 900,
            in: repo
        )
        XCTAssertEqual(page.changes.count, 100)
        XCTAssertFalse(page.hasMore)
        XCTAssertEqual(page.changes.map(\.path), Array(sortedPaths[900..<1_000]))
    }

    private func runAndRead(_ args: [String], in repo: URL) throws -> String {
        try GitProcessRunner.run(args, in: repo).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func testLoadDiffOnSelf() throws {
        let repo = selfRepoURL
        guard FileManager.default.fileExists(atPath: repo.appendingPathComponent(".git").path) else {
            throw XCTSkip("not inside a GitOK git checkout: \(repo.path)")
        }
        let commits = try GitCommitLoader.loadCommits(in: repo, limit: 5)
        guard let head = commits.first else {
            throw XCTSkip("no commits in self repo")
        }
        let changes = try GitDiffLoader.loadChanges(commit: head.hash, in: repo)
        guard let textFile = changes.first(where: { $0.status != .unknown }) else {
            throw XCTSkip("no changes in head commit")
        }
        let diff = try GitDiffLoader.loadDiff(commit: head.hash, filePath: textFile.path, in: repo)
        XCTAssertFalse(diff.isEmpty, "diff should not be empty for \(textFile.path)")
    }

    /// 非 UTF-8（GBK）编码文件：diff 不应被判定为空（回退 GB18030 / lossy 解码）。
    func testLoadDiffOnGBKFileIsNotEmpty() throws {
        let repo = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-diffprobe-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: repo) }
        try FileManager.default.createDirectory(at: repo, withIntermediateDirectories: true)

        func run(_ args: [String]) throws {
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/usr/bin/git")
            p.arguments = args
            p.currentDirectoryURL = repo
            p.standardOutput = Pipe()
            p.standardError = Pipe()
            try p.run()
            p.waitUntilExit()
        }
        try run(["init", "-q"])
        try run(["config", "user.email", "t@t.com"])
        try run(["config", "user.name", "t"])

        // 用 NSString 以 GBK 编码写出，确保字节非 UTF-8。
        let content = "{\"name\":\"中文数据\",\"desc\":\"测试\"}\n" as NSString
        let gbEncoding = CFStringConvertEncodingToNSStringEncoding(
            CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)
        )
        let gbBytes = try XCTUnwrap(content.data(using: gbEncoding))
        let fileURL = repo.appendingPathComponent("gbk_data.json")
        try gbBytes.write(to: fileURL)

        try run(["add", "-A"])
        try run(["commit", "-qm", "add gbk"])
        let hash = try GitProcessRunner.run(["rev-parse", "HEAD"], in: repo)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let diff = try GitDiffLoader.loadDiff(commit: hash, filePath: "gbk_data.json", in: repo)
        XCTAssertFalse(diff.isEmpty, "GBK file diff must not be empty")
        XCTAssertTrue(diff.contains("gbk_data.json"))
        // 中文内容应被解码（GB18030 成功）而非被吞掉。
        XCTAssertTrue(diff.contains("中文"), "GBK 内容应被解码出来")
    }

    /// 工作区 diff：已跟踪修改 / 未跟踪文件 / 未跟踪目录三种场景。
    func testLoadWorktreeDiff() throws {
        let repo = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-worktreediff-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: repo) }
        try FileManager.default.createDirectory(at: repo, withIntermediateDirectories: true)

        func run(_ args: [String]) throws {
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/usr/bin/git")
            p.arguments = args
            p.currentDirectoryURL = repo
            p.standardOutput = Pipe()
            p.standardError = Pipe()
            try p.run()
            p.waitUntilExit()
        }
        try run(["init", "-q"])
        try run(["config", "user.email", "t@t.com"])
        try run(["config", "user.name", "t"])

        // 已跟踪文件：提交后修改 → 工作区 diff 相对 HEAD 非空。
        try Data("line1\n".utf8).write(to: repo.appendingPathComponent("tracked.txt"))
        try run(["add", "tracked.txt"])
        try run(["commit", "-qm", "init"])
        try Data("line1\nline2\n".utf8).write(to: repo.appendingPathComponent("tracked.txt"))
        let trackedDiff = try GitDiffLoader.loadWorktreeDiff(filePath: "tracked.txt", in: repo)
        XCTAssertTrue(trackedDiff.contains("tracked.txt"), "tracked 修改应有 diff")
        XCTAssertTrue(trackedDiff.contains("+line2"))

        // 未跟踪文件：整文件作为新增展示。
        try Data("{\"name\":\"x\"}\n".utf8).write(to: repo.appendingPathComponent("untracked.json"))
        let untrackedDiff = try GitDiffLoader.loadWorktreeDiff(filePath: "untracked.json", in: repo)
        XCTAssertTrue(untrackedDiff.contains("new file mode"), "untracked 文件应以新增展示")
        XCTAssertTrue(untrackedDiff.contains("untracked.json"))

        // 未跟踪目录：git 无法生成文本 diff → 返回空串。
        try FileManager.default.createDirectory(
            at: repo.appendingPathComponent("newdir"),
            withIntermediateDirectories: true
        )
        try Data("icon".utf8).write(to: repo.appendingPathComponent("newdir/a.txt"))
        let dirDiff = try GitDiffLoader.loadWorktreeDiff(filePath: "newdir/", in: repo)
        XCTAssertTrue(dirDiff.isEmpty, "未跟踪目录应返回空 diff")
    }

    /// 工作区状态：干净与有变更两种场景。
    func testLoadStatusCleanAndDirty() throws {
        let repo = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-statusprobe-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: repo) }
        try FileManager.default.createDirectory(at: repo, withIntermediateDirectories: true)

        func run(_ args: [String]) throws {
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/usr/bin/git")
            p.arguments = args
            p.currentDirectoryURL = repo
            p.standardOutput = Pipe()
            p.standardError = Pipe()
            try p.run()
            p.waitUntilExit()
        }
        try run(["init", "-q"])
        try run(["config", "user.email", "t@t.com"])
        try run(["config", "user.name", "t"])
        try run(["checkout", "-q", "-b", "dev"])
        try Data("hello\n".utf8).write(to: repo.appendingPathComponent("a.txt"))
        try run(["add", "-A"])
        try run(["commit", "-qm", "init"])

        // clean
        var status = try GitStatusLoader.loadStatus(in: repo)
        XCTAssertTrue(status.isClean)
        XCTAssertEqual(status.changeCount, 0)
        XCTAssertEqual(status.branch, "dev")

        // dirty：修改一个文件
        try Data("hello world\n".utf8).write(to: repo.appendingPathComponent("a.txt"))
        status = try GitStatusLoader.loadStatus(in: repo)
        XCTAssertFalse(status.isClean)
        XCTAssertEqual(status.changeCount, 1)
        XCTAssertEqual(status.branch, "dev")
    }

    /// 未跟踪目录应展开为文件条目，避免不同 Git 后端出现目录 / 文件两种展示结果。
    func testLoadEntriesExpandsUntrackedDirectories() throws {
        let repo = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-untracked-directory-(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: repo) }
        try FileManager.default.createDirectory(at: repo, withIntermediateDirectories: true)

        func run(_ args: [String]) throws {
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/usr/bin/git")
            p.arguments = args
            p.currentDirectoryURL = repo
            p.standardOutput = Pipe()
            p.standardError = Pipe()
            try p.run()
            p.waitUntilExit()
        }
        try run(["init", "-q"])

        let nestedDirectory = repo.appendingPathComponent("Packages/ProviderToast/Sources/ProviderToast", isDirectory: true)
        try FileManager.default.createDirectory(at: nestedDirectory, withIntermediateDirectories: true)
        try Data("package\n".utf8).write(to: repo.appendingPathComponent("Packages/ProviderToast/Package.swift"))
        try Data("protocol\n".utf8).write(to: nestedDirectory.appendingPathComponent("ToastProviding.swift"))

        let entries = try GitStatusLoader.loadEntries(in: repo)
        XCTAssertEqual(
            entries.map(\.path).sorted(),
            [
                "Packages/ProviderToast/Package.swift",
                "Packages/ProviderToast/Sources/ProviderToast/ToastProviding.swift",
            ]
        )
        XCTAssertTrue(entries.allSatisfy(\.isUntracked))
        XCTAssertTrue(entries.allSatisfy { !$0.path.hasSuffix("/") })

        let status = try GitStatusLoader.loadStatus(in: repo)
        XCTAssertEqual(status.changeCount, 2)
    }
}
