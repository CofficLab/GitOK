import XCTest
@testable import FactoryGitOK
import KitGit
import ProviderProjects
import ProviderGit
import ProviderRootView
import ProviderStorage
import ProviderToast
import ProviderToolbar
import ProviderWorkspaceScene
import PluginCommitStatusBar
import PluginCommitToast
import PluginToast

/// 真实内核装配集成测试：验证内核启动基线。
///
/// 大部分插件在注册文件中声明 `disabled`（彻底停用，不可配置），因此启动后
/// 这些插件 onBoot 不会运行；两个 Git 后端是 required，由 ProviderGit 统一
/// 注册并按优先级管理。
///
/// 已恢复的插件（policy 非 `.disabled`，例如 `GitBranchStatusPlugin` 的
/// `.alwaysOn`）不在此基线断言范围内，各自有独立的插件级测试。
@MainActor
final class KernelBootIntegrationTests: XCTestCase {
    override func setUp() {
        super.setUp()
        let stateFile = DefaultStorageProvider.makeDefaultDataRootDirectory()
            .appendingPathComponent("com.coffic.gitok.plugin.plugin-manager", isDirectory: true)
            .appendingPathComponent("plugin-enabled-overrides.plist", isDirectory: false)
        try? FileManager.default.removeItem(at: stateFile)
    }

    /// 默认 disabled 插件不启动；required Git 后端与核心 Toast 插件会启动。
    func testBootLoadsRequiredGitBackends() throws {
        let kernel = try KernelFactory.makeKernel()

        // 宿主仍注册了默认 provider（保证 app 不崩、可渲染空壳）。
        XCTAssertNotNil(kernel.resolveProvider((any ProjectProviding).self))
        XCTAssertNotNil(kernel.resolveProvider((any ToastProviding).self))
        XCTAssertEqual(
            kernel.resolveProvider((any WorkspaceSceneProviding).self)?.currentScene,
            .git
        )
        let git = try XCTUnwrap(kernel.resolveProvider((any GitProviding).self))
        XCTAssertEqual(
            git.availableBackends.map(\.id),
            [
                "com.coffic.gitok.git-backend.cli",
                "com.coffic.gitok.git-backend.libgit2"
            ]
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
                $0.id == "toast"
            } == true,
            "toast and persistent error notices should share the toast root overlay"
        )
        XCTAssertTrue(
            kernel.resolveProvider((any RootViewProviding).self)?.overlays.contains {
                $0.id == "com.coffic.gitok.plugin.commit-form.error"
            } == true,
            "commit form failures should be mounted as a root overlay"
        )
    }

    func testGitBackendsAreRequired() async throws {
        let kernel = try KernelFactory.makeKernel()
        let git = try XCTUnwrap(kernel.resolveProvider((any GitProviding).self))
        let pluginID = "com.coffic.gitok.plugin.git-cli"

        XCTAssertTrue(kernel.isPluginEnabled(id: pluginID))
        do {
            try await kernel.disablePlugin(id: pluginID)
            XCTFail("required Git backends must not be disabled")
        } catch {
            // Required plugins reject runtime disable requests.
        }
        XCTAssertTrue(kernel.isPluginEnabled(id: pluginID))
        XCTAssertEqual(git.availableBackends.count, 2)
    }

    func testGitBackendsAreLoadedAndOrderedByPriority() throws {
        let kernel = try KernelFactory.makeKernel()
        let git = try XCTUnwrap(kernel.resolveProvider((any GitProviding).self))

        XCTAssertTrue(kernel.isPluginEnabled(id: "com.coffic.gitok.plugin.git-cli"))
        XCTAssertTrue(kernel.isPluginEnabled(id: "com.coffic.gitok.plugin.git-libgit2"))
        XCTAssertEqual(
            git.availableBackends.map(\.id),
            [
                "com.coffic.gitok.git-backend.cli",
                "com.coffic.gitok.git-backend.libgit2"
            ]
        )
    }
}
