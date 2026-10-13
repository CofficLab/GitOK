import Foundation
import XCTest

/// 冲突弹层的布局回归测试。
///
/// 弹层正文区是一个 `ScrollView`，滚动条绘制在它自身的 trailing 边。
/// 弹层根 `VStack` 整体套了 `.padding(DesignTokens.Spacing.md)`，所以当
/// 滚动条按 ScrollView 自身边界绘制时，它与弹层右边缘之间会固定残留
/// 一个内边距。这里通过比较弹层表面和滚动区域的右边界来复现该间距。
final class GitOKConflictResolverLayoutUITests: GitOKUITestCase {
    override var hasWorkingTreeChanges: Bool { false }

    /// 面板固定宽度，滚动区因此比表面窄一个内边距宽度。
    private enum Metrics {
        static let panelWidth: CGFloat = 680
        /// 允许 1pt 误差：滚动条可能绘制在 ScrollView 边界之外一点点。
        static let flushTolerance: CGFloat = 1
        /// 内容对齐断言的容差：文字排版基线会带来亚像素级差异。
        static let contentAlignmentTolerance: CGFloat = 8
        /// 行首图标相对滚动区边缘的内缩：内容内缩 Spacing.md(16) 加行卡片
        /// 自身的水平内边距 Spacing.sm(8)。
        static let expectedRowIconInset: CGFloat = 24
    }

    /// 弹层高度有限，冲突文件必须多到溢出，滚动条才会真正出现。
    private let conflictFileCount = 40

    /// 在应用启动前把夹具仓库置于「合并进行中且存在冲突」的状态，
    /// ConflictResolver 的 observer 读到 MERGE_HEAD 后会自动弹出弹层。
    override func seedAdditionalUIState() throws {
        try runGitAllowingFailure(["checkout", "--", "."])

        // 一条与 main 分叉的分支，逐个改写同一批文件。
        try runGitAllowingFailure(["checkout", "-b", "ui-conflict-source"])
        for index in 0..<conflictFileCount {
            let name = conflictFileName(index)
            try Data("source side \(index)\n".utf8).write(to: repositoryURL.appendingPathComponent(name))
        }
        try runGitAllowingFailure(["add", "."])
        try runGitAllowingFailure(["commit", "--quiet", "-m", "Source branch edits"])

        try runGitAllowingFailure(["checkout", "main"])
        for index in 0..<conflictFileCount {
            let name = conflictFileName(index)
            try Data("target side \(index)\n".utf8).write(to: repositoryURL.appendingPathComponent(name))
        }
        try runGitAllowingFailure(["add", "."])
        try runGitAllowingFailure(["commit", "--quiet", "-m", "Target branch edits"])

        // 这一步预期以非零码退出，并在仓库里留下 UU 冲突与 MERGE_HEAD。
        try runGitAllowingFailure(["merge", "ui-conflict-source"])
    }

    private func conflictFileName(_ index: Int) -> String {
        String(format: "ui-conflict-%02d.txt", index)
    }

    func testConflictListScrollbarSitsFlushAgainstPanelTrailingEdge() throws {
        let panel = element(identifier: "gitok.git.conflict.panel")
        XCTAssertTrue(panel.waitForExistence(timeout: 30), "The conflict resolver panel did not open")

        // 滚动区就是那个画滚动条的 ScrollView：它的 trailing 边就是滚动条的落点。
        let scrollArea = panel.scrollViews.firstMatch
        XCTAssertTrue(scrollArea.waitForExistence(timeout: 15), "The conflict file list has no scroll area")

        let panelFrame = panel.frame
        let scrollFrame = scrollArea.frame
        XCTAssertEqual(panelFrame.width, Metrics.panelWidth, accuracy: 1, "The panel is not at its fixed width")
        XCTAssertGreaterThan(
            panelFrame.height - scrollFrame.height, 0,
            "The conflict list should be shorter than the panel"
        )

        let trailingGap = panelFrame.maxX - scrollFrame.maxX
        XCTAssertLessThanOrEqual(
            trailingGap,
            Metrics.flushTolerance,
            """
            The conflict list's scrollbar is not flush with the panel's trailing edge. \
            Trailing gap: \(trailingGap)pt (panel \(panelFrame), scroll area \(scrollFrame)). \
            The scroll area sits inside the panel's content padding, so its scroll indicator \
            is inset from the panel edge by DesignTokens.Spacing.md.
            """
        )
    }

    /// 滚动条贴边不能靠牺牲内容内边距换来的：文件行仍然必须相对滚动区
    /// 自身保留内缩，否则会贴到面板圆角上。
    func testConflictRowsKeepInsetInsideTheNowFullWidthScrollArea() throws {
        let panel = element(identifier: "gitok.git.conflict.panel")
        XCTAssertTrue(panel.waitForExistence(timeout: 30), "The conflict resolver panel did not open")

        let scrollArea = panel.scrollViews.firstMatch
        XCTAssertTrue(scrollArea.waitForExistence(timeout: 15), "The conflict file list has no scroll area")

        // 行首锚点用警告图标：行文本前面还有图标宽度，把它算进内缩会
        // 引入与内边距无关的常数偏移。图标紧贴行卡片的内边缘。
        // 查询必须限定在面板子树内：弹层背后的工作区 Changes 列表里
        // 也有同名图标，不加限定会匹配到面板外的节点。
        let rowLeadingAnchor = panel.descendants(matching: .image)
            .matching(NSPredicate(format: "identifier == %@", "exclamationmark.triangle"))
            .firstMatch
        XCTAssertTrue(rowLeadingAnchor.waitForExistence(timeout: 10), "The first conflict row's status icon is missing")

        /// 滚动区现在贴满面板宽度，所以用它的 leading 边作为参照。行首图标
        /// 相对滚动区边缘的内缩 = 列表内容内边距 Spacing.md(16) + 行卡片
        /// 自身的水平内边距 Spacing.sm(8)。这个常量与滚动条是否贴边无关，
        /// 所以它成立就说明内容没有被推到面板圆角上。
        let rowInset = rowLeadingAnchor.frame.minX - scrollArea.frame.minX
        XCTAssertEqual(
            rowInset,
            Metrics.expectedRowIconInset,
            accuracy: Metrics.contentAlignmentTolerance,
            """
            Conflict rows lost their content inset inside the scroll area. \
            Row icon inset: \(rowInset)pt, expected about \(Metrics.expectedRowIconInset)pt.
            """
        )
    }
}
