import Foundation
import XCTest

/// 复现「左侧状态条显示未提交数量，但右侧详情区整块留白、提交表单漂到中间」。
///
/// 用户可见的症状（原始截图）：
/// - 左侧工作区状态条显示「有未提交的…(18) 未提交」；
/// - 右侧详情区整块空白；
/// - 提交表单漂在面板中间，而不是贴在内容区顶部。
///
/// 成因：工作区内容归属（`WorktreeContentOwner`）按**仓库**广播，而后台预热
/// 插件（`PluginGitWorktreePreheat`）会依次扫描侧边栏里的每一个项目。每次扫描
/// 结束都会把结论推给所有订阅者。
///
/// 变更列表插件订阅了这份广播，但必须自己过滤出「说的是当前项目」的那一条。
/// 一旦缺少过滤，别的（干净）项目的结论会串台覆盖当前项目：
/// - 当前项目是脏的 → 被覆盖成 `.clean` → 变更列表渲染 `EmptyView()` 不占布局；
/// - 干净概览此刻同样不占布局；
/// - 两块内容同时消失 → 主内容区 VStack 只剩提交表单 → VStack 塌陷 →
///   整个内容区被垂直居中 → 提交表单漂到面板中间。
///
/// 触发前提：侧边栏里同时存在**脏**和**干净**的项目。真实用户的仓库列表正是
/// 这种状态（本人机器上 30 个仓库中只有 GitOK 一个是脏的）。
///
/// 这里用两个夹具仓库复现该前提：当前项目有未提交改动，另一个项目干净。
final class GitOKWorktreeOwnerIsolationUITests: GitOKUITestCase {
    /// 注入额外的干净项目，模拟「预热插件会扫到别的仓库」。
    override func additionalProjectFixtures() throws -> [UITestProject] {
        let cleanURL = fixtureRootURL.appendingPathComponent("CleanRepository", isDirectory: true)
        try createCleanRepository(at: cleanURL)
        return [
            UITestProject(
                id: UUID(),
                url: cleanURL,
                title: "Clean Repository",
                isPinned: false
            ),
        ]
    }

    /// 当前项目有未提交改动时，变更列表必须展示出来，不能塌陷成空白。
    ///
    /// 这条断言直接对应用户截图里的症状：状态条说「有未提交」，右侧却是空的。
    func testChangesListIsVisibleWhileAnotherProjectIsBeingScanned() {
        let tracked = element(identifier: "gitok.worktree.file.tracked.txt")
        XCTAssertTrue(
            tracked.waitForExistence(timeout: 30),
            "当前项目有未提交改动，右侧变更列表必须展示文件行；"
                + "列表塌陷说明工作区归属被其它项目的扫描结果串台覆盖了"
        )
    }

    /// 变更列表塌陷时，主内容区只剩提交表单，VStack 塌陷会让表单被垂直居中。
    ///
    /// 这条断言锁定「提交表单必须贴在内容区顶部」这条用户可见约束。
    func testCommitFormStaysAnchoredToTopWhenAnotherProjectIsClean() {
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
            "提交表单被垂直居中（距顶部 \(offsetFromTop)pt），"
                + "说明详情区塌陷了——工作区归属被其它项目的扫描结果串台覆盖了"
        )
    }

    /// 干净概览与变更列表不得同时出现：两者共用同一份「工作区是否干净」判定。
    ///
    /// 串台会让两份内容互相抢位，或同时消失把主内容区掏空。
    func testCleanOverviewAndChangesListAreMutuallyExclusiveAcrossProjects() {
        let tracked = element(identifier: "gitok.worktree.file.tracked.txt")
        XCTAssertTrue(tracked.waitForExistence(timeout: 30), "变更列表没有展示被修改的文件")

        XCTAssertFalse(
            element(identifier: "gitok.worktree.clean.overview").exists,
            "干净概览与变更列表同时出现，两块内容互相抢位"
        )
    }
}
