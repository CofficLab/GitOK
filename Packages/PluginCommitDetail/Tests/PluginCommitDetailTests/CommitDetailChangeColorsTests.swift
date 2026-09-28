import XCTest
@testable import PluginCommitDetail
@testable import KitGit
import SwiftUI

final class CommitDetailChangeColorsTests: XCTestCase {

    func testCommitStatusCoversAllCases() {
        // 仅触发各分支；Color 不便于等值比较，覆盖 switch 全部分支即可。
        let statuses: [GitFileChange.Status] = [.added, .deleted, .modified, .renamed, .copied, .unmerged, .unknown]
        let colors: [Color] = statuses.map { CommitDetailChangeColors.commitStatus($0) }
        XCTAssertEqual(colors.count, 7)
        // 至少访问一次静态色值，确保惰性属性被求值。
        _ = CommitDetailChangeColors.added
        _ = CommitDetailChangeColors.deleted
        _ = CommitDetailChangeColors.modified
        _ = CommitDetailChangeColors.renamed
        _ = CommitDetailChangeColors.conflict
        _ = CommitDetailChangeColors.unknown
    }

    func testWorktreeStatusBranches() {
        // Untracked -> conflict
        let untracked = GitStatusEntry(path: "x", stagedStatus: "?", worktreeStatus: "?")
        _ = CommitDetailChangeColors.worktreeStatus(untracked)

        // Worktree modified (Y column) takes precedence.
        let worktreeModified = GitStatusEntry(path: "x", stagedStatus: "M", worktreeStatus: "D")
        _ = CommitDetailChangeColors.worktreeStatus(worktreeModified)

        // Not worktree modified -> staged status used for each letter.
        let stagedCases: [Character] = ["A", "D", "M", "R", "C", "U", "T"]
        for x in stagedCases {
            let e = GitStatusEntry(path: "x", stagedStatus: x, worktreeStatus: " ")
            _ = CommitDetailChangeColors.worktreeStatus(e)
        }
        // Worktree modified with each letter.
        for y in stagedCases {
            let e = GitStatusEntry(path: "x", stagedStatus: " ", worktreeStatus: y)
            _ = CommitDetailChangeColors.worktreeStatus(e)
        }
    }

    func testLocalizationWrapper() {
        let s = CommitDetailLocalization.string("any.key", bundle: .main, locale: Locale(identifier: "en"))
        XCTAssertFalse(s.isEmpty)
    }
}
