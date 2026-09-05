import XCTest
@testable import FactoryGitOK
import KitGit
import ProviderProjects
import ProviderRootView
import ProviderToast
import ProviderToolbar
import ProviderWorkspaceScene
import PluginCommitStatusBar
import PluginCommitToast
import PluginToast

/// 真实内核装配集成测试：验证内核启动基线。
///
/// 大部分插件在注册文件中声明 `disabled`（彻底停用，不可配置），因此启动后
/// 这些插件 onBoot 不会运行，Provider 保持宿主 `DefaultProviderFactory` 注册的
/// 默认实现；核心 Toast 插件需要始终启动，才能提供全局 RootView Overlay。
///
/// 已恢复的插件（policy 非 `.disabled`，例如 `GitBranchStatusPlugin` 的
/// `.alwaysOn`）不在此基线断言范围内，各自有独立的插件级测试。
@MainActor
final class KernelBootIntegrationTests: XCTestCase {
    /// 默认 disabled 插件不启动；核心 Toast 插件会替换宿主 no-op provider。
    func testBootDefaultsToDisabledPlugins() throws {
        let kernel = try KernelFactory.makeKernel()

        // 宿主仍注册了默认 provider（保证 app 不崩、可渲染空壳）。
        XCTAssertNotNil(kernel.resolveProvider((any ProjectProviding).self))
        XCTAssertNotNil(kernel.resolveProvider((any ToastProviding).self))
        XCTAssertEqual(
            kernel.resolveProvider((any WorkspaceSceneProviding).self)?.currentScene,
            .git
        )
        XCTAssertTrue(
            kernel.resolveProvider((any ToolbarProviding).self)?.toolbarItems.contains {
                $0.id == "workspace-scene-picker"
            } == true
        )

        // Toast 是核心能力，必须由插件启动并挂载 RootView Overlay。
        XCTAssertTrue(
            kernel.resolveProvider((any ToastProviding).self) is ToastCenter,
            "toast should be active so core errors can be rendered by the root overlay"
        )

        XCTAssertTrue(
            kernel.resolveProvider((any RootViewProviding).self)?.overlays.contains {
                $0.id == "com.coffic.gitok.plugin.worktree-status.sync-failure"
            } == true,
            "worktree sync failures should be mounted as a root overlay"
        )
        XCTAssertTrue(
            kernel.resolveProvider((any RootViewProviding).self)?.overlays.contains {
                $0.id == "com.coffic.gitok.plugin.commit-form.error"
            } == true,
            "commit form failures should be mounted as a root overlay"
        )
    }
}
