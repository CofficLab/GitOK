import Foundation
import KitGit
import ProviderGit
import ProviderProjects
import XCTest
@testable import PluginCommitDetail

/// 复现「右侧详情区整块留白、提交表单漂到面板中间」的成因。
///
/// 用户可见的症状（见 `GitOKWorktreeContentUITests`）：
/// 左侧状态条显示「有未提交的…(18) 未提交」，右侧详情区却整块留白，
/// 提交表单漂在面板中间。
///
/// 成因：工作区内容归属（`WorktreeContentOwner`）是**按仓库**广播的。
/// 预热插件（`PluginGitWorktreePreheat`）会在后台依次扫描侧边栏里的每一个
/// 项目，每次扫描结束都会发布一次归属结论，并把结论推给**所有**订阅者。
///
/// 变更列表插件（`PluginCommitDetail`）订阅了这份广播，但它必须自己判断
/// 「这条结论说的是不是当前项目」。一旦缺少这层过滤，别的仓库的结论就会
/// 串台覆盖当前项目的结论：
///
/// - 当前项目是脏的（`.changes`）→ 被别的干净仓库（`.clean`）覆盖
///   → 变更列表判定「工作区干净」→ 渲染 `EmptyView()` 不占布局；
/// - 干净概览（`PluginWorktreeClean`）此刻要么还没完成首次扫描，要么因为
///   自身条件不满足同样不占布局；
/// - 两块内容同时不占布局 → 主内容区 VStack 只剩提交表单 → VStack 高度塌陷
///   → 整个内容区被垂直居中 → 提交表单漂到面板中间。
///
/// 这组测试锁定「归属广播必须按仓库隔离」这条约束。
@MainActor
final class CommitDetailWorktreeOwnerIsolationTests: XCTestCase {
    private let currentProjectURL = URL(fileURLWithPath: "/tmp/current-project")
    private let otherProjectURL = URL(fileURLWithPath: "/tmp/other-project")

    // MARK: - Reproduction

    /// 核心复现：当前项目是脏的，但后台扫描另一个干净项目时，
    /// 当前项目的归属结论被覆盖成 `.clean`。
    ///
    /// 这条断言在修复前必然失败——`CommitDetailObserver` 缺少 `url` 过滤。
    func testOwnerBroadcastForAnotherRepositoryDoesNotOverwriteCurrentProject() {
        let git = WorktreeOwnerGitDouble()
        let projects = WorktreeOwnerProjectsDouble()
        projects.currentProject = Project(url: currentProjectURL, lastOpenedAt: Date())

        let viewModel = CommitDetailViewModel()
        let observer = CommitDetailObserver(
            capability: CommitDetailProjectCapabilityAdapter(projects: projects),
            gitWatch: nil,
            git: git,
            viewModel: viewModel
        )
        defer { observer.cancel() }

        // 当前项目扫描完毕：工作区有改动 → 归属为 .changes。
        git.simulateScan(publishing: .changes, for: currentProjectURL)
        XCTAssertEqual(viewModel.worktreeOwner, .changes)

        // 后台预热扫描了另一个**干净**项目，并广播了它的结论。
        git.simulateScan(publishing: .clean, for: otherProjectURL)

        // 当前项目的结论必须保持不变。
        XCTAssertEqual(
            viewModel.worktreeOwner,
            .changes,
            "另一个仓库的归属结论串台覆盖了当前项目，导致变更列表塌陷成 EmptyView"
        )
    }

    /// 反向：当前项目干净时，别的**脏**项目也不能把它改成 `.changes`。
    ///
    /// 否则变更列表会突然在干净项目上冒出来（与上面是同一个 bug 的镜像）。
    func testDirtyBroadcastForAnotherRepositoryDoesNotOverwriteCleanCurrentProject() {
        let git = WorktreeOwnerGitDouble()
        let projects = WorktreeOwnerProjectsDouble()
        projects.currentProject = Project(url: currentProjectURL, lastOpenedAt: Date())

        let viewModel = CommitDetailViewModel()
        let observer = CommitDetailObserver(
            capability: CommitDetailProjectCapabilityAdapter(projects: projects),
            gitWatch: nil,
            git: git,
            viewModel: viewModel
        )
        defer { observer.cancel() }

        git.simulateScan(publishing: .clean, for: currentProjectURL)
        XCTAssertEqual(viewModel.worktreeOwner, .clean)

        git.simulateScan(publishing: .changes, for: otherProjectURL)

        XCTAssertEqual(
            viewModel.worktreeOwner,
            .clean,
            "另一个仓库的归属结论串台覆盖了当前项目"
        )
    }

    /// 当前项目自己的结论仍然必须能正常生效（过滤不能过头）。
    func testOwnerBroadcastForCurrentProjectStillApplies() {
        let git = WorktreeOwnerGitDouble()
        let projects = WorktreeOwnerProjectsDouble()
        projects.currentProject = Project(url: currentProjectURL, lastOpenedAt: Date())

        let viewModel = CommitDetailViewModel()
        let observer = CommitDetailObserver(
            capability: CommitDetailProjectCapabilityAdapter(projects: projects),
            gitWatch: nil,
            git: git,
            viewModel: viewModel
        )
        defer { observer.cancel() }

        git.simulateScan(publishing: .changes, for: currentProjectURL)
        XCTAssertEqual(viewModel.worktreeOwner, .changes)

        git.simulateScan(publishing: .clean, for: currentProjectURL)
        XCTAssertEqual(viewModel.worktreeOwner, .clean)
    }

    /// 串台的直接后果：变更列表塌陷成 `EmptyView`（不占布局）。
    ///
    /// 这个断言把「归属被串台」翻译成用户真正看到的症状，
    /// 让失败信息直接指向问题本身而不是内部状态。
    func testCrossTalkCollapsesTheChangesListIntoAnEmptyBlock() {
        let git = WorktreeOwnerGitDouble()
        let projects = WorktreeOwnerProjectsDouble()
        projects.currentProject = Project(url: currentProjectURL, lastOpenedAt: Date())

        let viewModel = CommitDetailViewModel()
        let observer = CommitDetailObserver(
            capability: CommitDetailProjectCapabilityAdapter(projects: projects),
            gitWatch: nil,
            git: git,
            viewModel: viewModel
        )
        defer { observer.cancel() }

        git.simulateScan(publishing: .changes, for: currentProjectURL)
        // 当前项目确实有 18 个改动（与用户仓库一致）。
        let entries = (0..<18).map {
            GitStatusEntry(path: "file\($0).xcstrings", stagedStatus: " ", worktreeStatus: "M")
        }

        let before = WorktreeChangesContentPolicy.resolve(
            owner: viewModel.worktreeOwner,
            entries: entries,
            loadError: nil
        )
        XCTAssertEqual(before, .changes(entries), "归属正确时变更列表必须展示文件列表")

        // 另一个干净项目被扫描，结论串台。
        git.simulateScan(publishing: .clean, for: otherProjectURL)

        let after = WorktreeChangesContentPolicy.resolve(
            owner: viewModel.worktreeOwner,
            entries: entries,
            loadError: nil
        )
        XCTAssertNotEqual(
            after,
            .clean,
            "归属被串台成 .clean 后，变更列表会渲染 EmptyView 不占布局，主内容区随之塌陷"
        )
    }
}
