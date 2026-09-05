import XCTest
@testable import FactoryGitOK
import KitGit
import ProviderProjects
import ProviderToast
import ProviderWorkspaceScene
import PluginCommitStatusBar
import PluginCommitToast
import PluginToast

/// 真实内核装配集成测试：验证内核启动基线。
///
/// 大部分插件在注册文件中声明 `disabled`（彻底停用，不可配置），因此启动后
/// 这些插件 onBoot 不会运行，Provider 保持宿主 `DefaultProviderFactory` 注册的
/// 默认实现；启用插件的替换逻辑在插件被逐个恢复为可配置策略后再验证。
///
/// 已恢复的插件（policy 非 `.disabled`，例如 `GitBranchStatusPlugin` 的
/// `.alwaysOn`）不在此基线断言范围内，各自有独立的插件级测试。
@MainActor
final class KernelBootIntegrationTests: XCTestCase {
    /// 默认 disabled：插件 onBoot 未运行，provider 保持宿主默认实现。
    func testBootDefaultsToDisabledPlugins() throws {
        let kernel = try KernelFactory.makeKernel()

        // 宿主仍注册了默认 provider（保证 app 不崩、可渲染空壳）。
        XCTAssertNotNil(kernel.resolveProvider((any ProjectProviding).self))
        XCTAssertNotNil(kernel.resolveProvider((any ToastProviding).self))
        XCTAssertEqual(
            kernel.resolveProvider((any WorkspaceSceneProviding).self)?.currentScene,
            .git
        )

        // 但插件 onBoot 的替换没有发生。
        XCTAssertFalse(
            kernel.resolveProvider((any ToastProviding).self) is ToastCenter,
            "toast should be disabled; provider should stay the host no-op"
        )
    }
}
