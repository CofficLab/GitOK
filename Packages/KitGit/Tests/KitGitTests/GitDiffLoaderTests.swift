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
}
