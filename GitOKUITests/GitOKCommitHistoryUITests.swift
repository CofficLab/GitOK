import Foundation
import XCTest

/// 覆盖 commit 历史列表与 diff 面板的端到端行为。
///
/// 既有用例只验证了「选中文件会打开 diff 面板」和「提交会写进 Git」，
/// 没有验证两者的连接：
/// - 提交之后新 commit 是否自动出现在历史列表（`dataChanged` → 强制重载）；
/// - diff 面板是否真的渲染出改动前后的内容（而不只是挂载了一个空面板）。
final class GitOKCommitHistoryUITests: GitOKUITestCase {
    func testNewCommitAppearsInCommitHistoryList() throws {
        // 1. 暂存夹具里的改动。
        let stage = element(identifier: "gitok.worktree.stage.tracked.txt")
        XCTAssertTrue(stage.waitForExistence(timeout: 20), "The modified fixture file is missing from Changes")
        stage.click()
        XCTAssertTrue(
            waitForLabel(element(identifier: "gitok.worktree.status.tracked.txt"), toEqual: "Staged"),
            "The fixture change did not stage"
        )

        // 2. 用唯一 subject 提交。
        let subject = element(identifier: "gitok.commit.subject")
        XCTAssertTrue(subject.waitForExistence(timeout: 10), "The commit subject field is missing")
        let marker = "ui-history-\(UUID().uuidString)"
        replaceText(in: subject, with: marker)

        let commit = element(identifier: "gitok.commit.submit")
        XCTAssertTrue(waitUntilEnabled(commit), "The Commit action should be enabled for a staged change")
        commit.click()

        // 3. Git 侧先落库。
        let deadline = Date().addingTimeInterval(15)
        var latestSubject = ""
        while Date() < deadline {
            latestSubject = try gitOutput(["log", "-1", "--format=%s"])
            if latestSubject.contains(marker) { break }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        XCTAssertTrue(latestSubject.contains(marker), "The new commit was not written to Git")

        // 4. 历史列表应自动刷新出新 commit。
        let row = app.buttons
            .matching(NSPredicate(format: "label CONTAINS %@", marker))
            .firstMatch
        XCTAssertTrue(
            row.waitForExistence(timeout: 20),
            "The new commit did not appear in the commit history list"
        )
    }

    func testDiffPanelRendersChangedContent() {
        // 选中工作区里的改动文件，打开 diff。
        let file = element(identifier: "gitok.worktree.file.tracked.txt")
        XCTAssertTrue(file.waitForExistence(timeout: 20), "The modified fixture file is missing from Changes")
        file.click()

        let diffPanel = element(identifier: "gitok.git.diff.panel")
        XCTAssertTrue(diffPanel.waitForExistence(timeout: 15), "Selecting the changed file did not open its diff")

        // diff 面板应渲染出新增行与被删除行的内容，而不只是空面板。
        // 注意：MagicDiffView 里的行内容是 SwiftUI Text，在辅助功能树上以
        // `value`（而非 `label`）暴露，与工作区状态行一致。
        let added = app.staticTexts
            .matching(NSPredicate(format: "value CONTAINS %@", "modified by the UI test"))
            .firstMatch
        XCTAssertTrue(
            added.waitForExistence(timeout: 20),
            "The diff panel did not render the added line"
        )

        let removed = app.staticTexts
            .matching(NSPredicate(format: "value CONTAINS %@", "initial content"))
            .firstMatch
        XCTAssertTrue(
            removed.waitForExistence(timeout: 10),
            "The diff panel did not render the removed line"
        )
    }
}
