import Foundation
import XCTest

/// 冲突弹层的交互回归测试。
///
/// 布局类断言在 `GitOKConflictResolverLayoutUITests`，这里只覆盖行为：
/// 解决冲突 → 暂存 → 继续合并 → 弹层关闭，以及中止合并的确认与取消两条路径。
/// 每一步都用真实 git 校验仓库状态，避免只断言 UI 而漏掉实际没写 Git。
final class GitOKConflictResolverUITests: GitOKUITestCase {
    override var hasWorkingTreeChanges: Bool { false }

    private let conflictedFile = "conflict.txt"

    /// 在应用启动前把夹具仓库置于「合并进行中且存在冲突」的状态。
    ///
    /// ConflictResolver 的 observer 读到 MERGE_HEAD 后会自动弹出弹层，
    /// 因此这里不能依赖手动打开。`git merge` 预期以非零码退出，
    /// 测试真正关心的是它留下的 UU 冲突与 MERGE_HEAD。
    override func seedAdditionalUIState() throws {
        try runGitAllowingFailure(["checkout", "--", "."])

        // 一个与 main 分叉的分支，各自新增同名文件。
        // git 会判定为 add/add 冲突（非 fast-forward），留下 UU 与 MERGE_HEAD。
        try runGitAllowingFailure(["checkout", "-b", "conflict-source"])
        try Data("source side\n".utf8).write(to: repositoryURL.appendingPathComponent(conflictedFile))
        try runGitAllowingFailure(["add", "."])
        try runGitAllowingFailure(["commit", "--quiet", "-m", "Source side"])

        try runGitAllowingFailure(["checkout", "main"])
        try Data("target side\n".utf8).write(to: repositoryURL.appendingPathComponent(conflictedFile))
        try runGitAllowingFailure(["add", "."])
        try runGitAllowingFailure(["commit", "--quiet", "-m", "Target side"])

        // 预期以非零码退出；测试真正关心的是它留下的 UU 冲突与 MERGE_HEAD。
        try runGitAllowingFailure(["merge", "conflict-source"])
    }

    // MARK: - Helpers

    private func conflictPanel() -> XCUIElement {
        element(identifier: "gitok.git.conflict.panel")
    }

    /// 等待弹层出现。observer 依赖仓库监听事件触发，时序不由测试控制。
    @discardableResult
    private func waitForPanel(timeout: TimeInterval = 30) -> Bool {
        conflictPanel().waitForExistence(timeout: timeout)
    }

    /// 轮询等待仓库状态满足条件，给后台 git 进程留出完成时间。
    private func waitForGit(
        timeout: TimeInterval = 20,
        _ description: String,
        _ condition: () throws -> Bool
    ) rethrows {
        let deadline = Date().addingTimeInterval(timeout)
        var lastError: Error?
        while Date() < deadline {
            if (try? condition()) == true { return }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        if let lastError {
            XCTFail("Timed out waiting until \(description): \(lastError)")
        } else {
            XCTFail("Timed out waiting until \(description)")
        }
    }

    /// 中止确认弹窗。
    ///
    /// SwiftUI 的 `.alert` 在 macOS 上以 sheet 形式挂载，`app.alerts` 取不到它。
    /// 这里同时接受两种呈现方式，避免因宿主控件差异而漏测确认流程。
    private func abortConfirmation() -> XCUIElement {
        let sheet = app.sheets.firstMatch
        let alert = app.alerts.firstMatch
        let deadline = Date().addingTimeInterval(10)
        while Date() < deadline {
            if sheet.exists { return sheet }
            if alert.exists { return alert }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        return sheet.exists ? sheet : alert
    }

    // MARK: - 主流程

    /// 通过弹层的「使用对方版本」解决冲突并完成合并。
    ///
    /// 注意：行内动作在 checkout 之后会顺带 `git add`，因此解决后文件直接进入
    /// 「已暂存」状态，正文区清空、顶部出现可用的「继续」按钮——不会经过
    /// 「已解决待暂存」这一步。手动编辑的路径由
    /// `testManuallyEditedFileOffersStagingBeforeContinuing` 覆盖。
    func testResolvingWithTheirsAndContinuingCompletesTheMerge() throws {
        XCTAssertTrue(waitForPanel(), "The conflict resolver panel did not open")
        XCTAssertTrue(
            element(identifier: "gitok.git.conflict.more.\(conflictedFile)").waitForExistence(timeout: 15),
            "The conflicted file row is missing from the panel"
        )

        // 未解决时不应出现暂存入口：没有任何文件已解决。
        XCTAssertFalse(
            element(identifier: "gitok.git.conflict.stage").waitForExistence(timeout: 2),
            "Stage must stay hidden while the conflict is still unresolved"
        )
        // 继续按钮可见但禁用。
        let continueButton = element(identifier: "gitok.git.conflict.continue")
        XCTAssertTrue(
            continueButton.waitForExistence(timeout: 5),
            "The Continue action is missing while conflicts remain"
        )
        XCTAssertFalse(continueButton.isEnabled, "Continue must be disabled until conflicts are resolved")

        // 通过「使用对方版本」解决冲突。
        let more = element(identifier: "gitok.git.conflict.more.\(conflictedFile)")
        more.click()
        let useTheirs = element(identifier: "gitok.git.conflict.use-theirs")
        XCTAssertTrue(useTheirs.waitForExistence(timeout: 10), "The per-file actions popover did not open")
        useTheirs.click()

        // 冲突标记应从文件中消失，且文件已被暂存。
        try waitForGit("the conflict markers are gone") {
            let contents = try String(contentsOf: repositoryURL.appendingPathComponent(self.conflictedFile), encoding: .utf8)
            return !contents.contains("<<<<<<<")
        }

        // 全部暂存后继续按钮变为可用。
        XCTAssertTrue(
            waitUntilEnabled(continueButton, timeout: 20),
            "Continue must become available once every conflict is resolved and staged"
        )
        continueButton.click()

        // 合并完成：MERGE_HEAD 消失，且产生了一个合并提交。
        try waitForGit("the merge completed") {
            try self.gitOutput(["rev-parse", "--verify", "-q", "MERGE_HEAD"], allowFailure: true).isEmpty
        }
        XCTAssertEqual(
            try gitOutput(["show", ":\(conflictedFile)"]),
            // 当前 HEAD 是 main，正在把 conflict-source 合入，因此
            // ours = main 的 target side，theirs = conflict-source 的 source side。
            // 「使用对方版本」取 theirs，结果应为 source side。
            "source side",
            "Continuing the merge should have committed the staged resolution"
        )

        // 操作结束后弹层必须自行关闭。
        XCTAssertTrue(
            conflictPanel().waitForNonExistence(timeout: 20),
            "The conflict panel stayed open after the merge completed"
        )
    }

    /// 在外部手工改好文件但未暂存时，弹层必须提供暂存入口，且继续仍被禁用。
    ///
    /// 这是「已解决待暂存」状态的唯一真实来源：行内的 use-ours/theirs/base
    /// 都会顺带 `git add`，不会停在这个状态。
    func testManuallyEditedFileOffersStagingBeforeContinuing() throws {
        XCTAssertTrue(waitForPanel(), "The conflict resolver panel did not open")

        // 模拟用户在外部编辑器里手工整理好冲突内容，但没有执行 git add。
        try Data("hand resolved\n".utf8).write(to: repositoryURL.appendingPathComponent(conflictedFile))

        let stage = element(identifier: "gitok.git.conflict.stage")
        XCTAssertTrue(
            stage.waitForExistence(timeout: 20),
            "Staging must be offered once the file is resolved but not staged"
        )

        let continueButton = element(identifier: "gitok.git.conflict.continue")
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        XCTAssertFalse(
            waitUntilEnabled(continueButton, timeout: 2),
            "Continue must stay disabled until the resolved file is staged"
        )
        // 注意：冲突未解决时文件已带 stage 1/2/3 出现在 --cached 中，
        // 因此不能用 `diff --cached --name-only` 判断「是否已解决并暂存」，
        // 必须看是否还残留未合并的 stage（`ls-files -u` 会输出 3 行 stage 记录）。
        XCTAssertFalse(
            try gitOutput(["ls-files", "-u", "--", conflictedFile]).isEmpty,
            "The fixture file should still be unmerged before the test stages it"
        )

        stage.click()
        try waitForGit("the resolved file is staged") {
            try self.gitOutput(["ls-files", "-u", "--", self.conflictedFile]).isEmpty
        }

        XCTAssertTrue(
            waitUntilEnabled(continueButton, timeout: 20),
            "Continue must become available once the manually resolved file is staged"
        )
    }

    /// 继续合并前必须先暂存，否则 Git 会拒绝；这里验证按钮的禁用确实生效。
    func testContinueStaysDisabledUntilResolvedFilesAreStaged() throws {
        XCTAssertTrue(waitForPanel(), "The conflict resolver panel did not open")

        element(identifier: "gitok.git.conflict.more.\(conflictedFile)").click()
        let useTheirs = element(identifier: "gitok.git.conflict.use-theirs")
        XCTAssertTrue(useTheirs.waitForExistence(timeout: 10), "The per-file actions popover did not open")
        useTheirs.click()

        try waitForGit("the conflict markers are gone") {
            let contents = try String(contentsOf: repositoryURL.appendingPathComponent(self.conflictedFile), encoding: .utf8)
            return !contents.contains("<<<<<<<")
        }

        let continueButton = element(identifier: "gitok.git.conflict.continue")
        XCTAssertTrue(continueButton.waitForExistence(timeout: 15))
        // 确认 merge 还没被提前提交。
        XCTAssertFalse(
            try gitOutput(["rev-parse", "--verify", "-q", "MERGE_HEAD"], allowFailure: true).isEmpty,
            "The fixture merge should still be in progress"
        )
        XCTAssertFalse(
            try gitOutput(["status", "--porcelain"]).isEmpty,
            "The merge should not have been committed by resolving alone"
        )
    }

    // MARK: - 中止合并

    /// 确认中止：仓库应回到合并前状态，弹层关闭。
    func testAbortingTheMergeRestoresTheRepositoryAndClosesThePanel() throws {
        XCTAssertTrue(waitForPanel(), "The conflict resolver panel did not open")

        let abort = element(identifier: "gitok.git.conflict.abort")
        XCTAssertTrue(abort.waitForExistence(timeout: 10), "The Abort action is missing")
        abort.click()

        let confirmation = abortConfirmation()
        XCTAssertTrue(confirmation.exists, "Aborting did not ask for confirmation")
        let confirm = confirmation.buttons["Abort Merge"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "The confirmation has no Abort Merge action")
        confirm.click()

        try waitForGit("the merge was aborted") {
            try self.gitOutput(["rev-parse", "--verify", "-q", "MERGE_HEAD"], allowFailure: true).isEmpty
        }
        XCTAssertEqual(
            try String(contentsOf: repositoryURL.appendingPathComponent(conflictedFile), encoding: .utf8),
            "target side\n",
            "Aborting must restore the file to the pre-merge state"
        )
        XCTAssertEqual(
            try gitOutput(["status", "--porcelain"]),
            "",
            "Aborting must leave a clean working tree"
        )
        XCTAssertTrue(
            conflictPanel().waitForNonExistence(timeout: 20),
            "The conflict panel stayed open after the merge was aborted"
        )
    }

    /// 取消中止：仓库必须保持冲突状态，弹层继续可见。
    func testCancellingTheAbortConfirmationKeepsTheMergeInProgress() throws {
        XCTAssertTrue(waitForPanel(), "The conflict resolver panel did not open")

        let abort = element(identifier: "gitok.git.conflict.abort")
        XCTAssertTrue(abort.waitForExistence(timeout: 10), "The Abort action is missing")
        abort.click()

        let confirmation = abortConfirmation()
        XCTAssertTrue(confirmation.exists, "Aborting did not ask for confirmation")
        let cancel = confirmation.buttons["Cancel"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 5), "The Abort confirmation has no Cancel action")
        cancel.click()

        XCTAssertTrue(
            confirmation.waitForNonExistence(timeout: 5),
            "Cancelling should close the confirmation"
        )
        XCTAssertTrue(
            conflictPanel().waitForExistence(timeout: 5),
            "Cancelling must leave the conflict panel open"
        )
        XCTAssertFalse(
            try gitOutput(["rev-parse", "--verify", "-q", "MERGE_HEAD"], allowFailure: true).isEmpty,
            "Cancelling Abort must leave the merge in progress"
        )
        XCTAssertEqual(
            try gitOutput(["diff", "--name-only", "--diff-filter=U"]),
            conflictedFile,
            "Cancelling Abort must leave the conflict intact"
        )
    }

    /// 关闭按钮只是收起弹层，不应中止 Git 操作。
    func testClosingThePanelLeavesTheMergeInProgress() throws {
        XCTAssertTrue(waitForPanel(), "The conflict resolver panel did not open")

        let close = element(identifier: "gitok.git.conflict.close")
        XCTAssertTrue(close.waitForExistence(timeout: 10), "The Close action is missing")
        close.click()

        XCTAssertTrue(
            conflictPanel().waitForNonExistence(timeout: 10),
            "Close did not dismiss the conflict panel"
        )
        XCTAssertFalse(
            try gitOutput(["rev-parse", "--verify", "-q", "MERGE_HEAD"], allowFailure: true).isEmpty,
            "Closing the panel must not abort the in-progress merge"
        )
        XCTAssertEqual(
            try gitOutput(["diff", "--name-only", "--diff-filter=U"]),
            conflictedFile,
            "Closing the panel must leave the conflict intact"
        )
    }
}
