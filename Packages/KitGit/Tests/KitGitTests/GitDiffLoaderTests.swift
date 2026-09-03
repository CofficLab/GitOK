import Foundation
import XCTest
@testable import KitGit

final class GitDiffLoaderTests: XCTestCase {
    /// 在当前仓库根（GitOK 自身）上做只读冒烟测试。
    func testLoadChangesOnSelf() throws {
        let repo = URL(fileURLWithPath: "/Users/colorfy/Code/CofficLab/GitOK")
        let commits = try GitCommitLoader.loadCommits(in: repo, limit: 5)
        guard let head = commits.first else {
            throw XCTSkip("no commits in self repo")
        }
        let changes = try GitDiffLoader.loadChanges(commit: head.hash, in: repo)
        XCTAssertFalse(changes.isEmpty)
        XCTAssertTrue(changes.allSatisfy { !$0.path.isEmpty })
    }

    func testLoadDiffOnSelf() throws {
        let repo = URL(fileURLWithPath: "/Users/colorfy/Code/CofficLab/GitOK")
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
}
