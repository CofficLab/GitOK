import Foundation
import XCTest

/// 工作区内容区（变更列表 / 干净概览）的呈现约束。
///
/// 用户可见的症状：打开仓库后，右侧详情区会整块留白，提交表单漂到面板中间，
/// 几秒后变更列表才出现。根因是变更列表与干净概览各自判断「工作区是否干净」，
/// 两者同时「不占布局」时主内容区塌陷。
///
/// 这里用 UI 测试守住修复后的三条约束：
/// 1. 扫描进行中详情区必须有加载占位，不能整块空白；
/// 2. 工作区有改动时，变更列表的计数必须与实际行数一致；
/// 3. 工作区有改动时，提交表单必须保持在内容区顶部，不能被垂直居中。
final class GitOKWorktreeContentUITests: GitOKUITestCase {
    /// 注入工作区扫描延迟，稳定复现「扫描尚未完成」的中间态。
    ///
    /// 延迟必须长于应用启动装配内容区的耗时，否则等详情区渲染出来时扫描已经
    /// 结束，中间态一闪而过、断言不稳定。
    override var additionalLaunchEnvironment: [String: String] {
        ["GITOK_UI_TEST_WORKTREE_DELAY_MS": "10000"]
    }

    /// 扫描进行中：变更列表必须展示加载占位，详情区不能整块留白。
    func testChangesPanelShowsLoadingPlaceholderWhileScanIsPending() {
        let loading = element(identifier: "gitok.worktree.loading")
        XCTAssertTrue(
            loading.waitForExistence(timeout: 20),
            "工作区扫描进行中时，变更列表必须展示加载占位，而不是整块留白"
        )
    }

    /// 工作区有改动时，变更列表的计数必须与实际行数一致。
    ///
    /// 用户截图里的症状正是「状态条显示 2 个改动，右侧列表却是空的」——
    /// 两处读到不同快照的表现。
    func testChangesCountMatchesRenderedFileRows() {
        let tracked = element(identifier: "gitok.worktree.file.tracked.txt")
        XCTAssertTrue(tracked.waitForExistence(timeout: 30), "变更列表没有展示被修改的文件")

        let countElement = element(identifier: "gitok.worktree.count")
        XCTAssertTrue(countElement.waitForExistence(timeout: 10), "变更列表缺少计数标识")

        let rows = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "gitok.worktree.file."))
            .allElementsBoundByIndex
        XCTAssertFalse(rows.isEmpty, "变更列表没有渲染任何文件行")

        let label = (countElement.label.isEmpty ? countElement.value : countElement.label) as? String
        XCTAssertEqual(
            Int(label ?? ""),
            rows.count,
            "变更列表计数（\(label ?? "nil")）必须与实际行数（\(rows.count)）一致"
        )
    }

    /// 工作区有改动时，提交表单必须保持在内容区顶部。
    ///
    /// 详情区塌陷时内容区 VStack 只剩表单，会被整体垂直居中——表单漂到面板中间，
    /// 正是用户截图里的样子。
    func testCommitFormStaysAnchoredToTopOfContentArea() {
        let subject = element(identifier: "gitok.commit.subject")
        XCTAssertTrue(subject.waitForExistence(timeout: 30), "提交表单没有出现")

        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 10))

        let subjectFrame = subject.frame
        let windowFrame = window.frame
        let offsetFromTop = subjectFrame.midY - windowFrame.minY
        XCTAssertLessThan(
            offsetFromTop,
            windowFrame.height * 0.35,
            "提交表单被垂直居中（距顶部 \(offsetFromTop)pt），说明详情区塌陷了"
        )
    }

    /// 干净概览与变更列表不得同时出现：两者共用同一份「工作区是否干净」判定。
    func testCleanOverviewAndChangesListAreMutuallyExclusive() {
        let tracked = element(identifier: "gitok.worktree.file.tracked.txt")
        XCTAssertTrue(tracked.waitForExistence(timeout: 30), "变更列表没有展示被修改的文件")

        XCTAssertFalse(
            element(identifier: "gitok.worktree.clean.overview").exists,
            "干净概览与变更列表同时出现，两块内容互相抢位"
        )
    }
}
