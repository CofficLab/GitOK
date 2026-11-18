import XCTest
@testable import GitOK
import KitGit
import ProviderProjects
import ProviderGit
import ProviderGitConflictResolver
import ProviderRootView
import ProviderSettingView
import ProviderTheme
import ProviderToast
import ProviderToolbar
import ProviderWorkspaceScene
import PluginToast

/// 真实内核装配集成测试：验证内核启动基线。
///
/// 大部分插件在注册文件中声明 `disabled`（彻底停用，不可配置），因此启动后
/// 这些插件 onBoot 不会运行；LibGit2 后端是 required，由 ProviderGit 统一
/// 注册。
///
/// 已恢复的插件（policy 非 `.disabled`，例如 `GitBranchStatusPlugin` 的
/// `.alwaysOn`）不在此基线断言范围内，各自有独立的插件级测试。
@MainActor
final class KernelBootIntegrationTests: GitOKKernelTestCase {

    /// 默认 disabled 插件不启动；required Git 后端与核心 Toast 插件会启动。
    func testBootLoadsRequiredGitBackends() async throws {
        let kernel = try await makeKernel()

        // 宿主仍注册了默认 provider（保证 app 不崩、可渲染空壳）。
        XCTAssertNotNil(kernel.resolveProvider((any ProjectProviding).self))
        XCTAssertNotNil(kernel.resolveProvider((any ToastProviding).self))
        XCTAssertNotNil(
            kernel.resolveProvider((any GitConflictResolutionProviding).self),
            "the conflict resolver must expose its presentation capability to workspace actions"
        )
        XCTAssertEqual(
            kernel.resolveProvider((any WorkspaceSceneProviding).self)?.currentScene,
            .git
        )
        let git = try XCTUnwrap(kernel.resolveProvider((any GitProviding).self))
        XCTAssertEqual(
            git.availableBackends.map(\.id),
            ["com.coffic.gitok.git-backend.libgit2"]
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
                $0.id == ToastSuperPlugin.overlayID
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
        let kernel = try await makeKernel()
        let git = try XCTUnwrap(kernel.resolveProvider((any GitProviding).self))
        let pluginID = "com.coffic.gitok.plugin.git-libgit2"

        XCTAssertTrue(kernel.isPluginEnabled(id: pluginID))
        do {
            try await kernel.disablePlugin(id: pluginID)
            XCTFail("required Git backends must not be disabled")
        } catch {
            // Required plugins reject runtime disable requests.
        }
        XCTAssertTrue(kernel.isPluginEnabled(id: pluginID))
        XCTAssertEqual(git.availableBackends.count, 1)
    }

    func testGitBackendsAreLoadedAndOrderedByPriority() async throws {
        let kernel = try await makeKernel()
        let git = try XCTUnwrap(kernel.resolveProvider((any GitProviding).self))

        XCTAssertTrue(kernel.isPluginEnabled(id: "com.coffic.gitok.plugin.git-libgit2"))
        XCTAssertEqual(
            git.availableBackends.map(\.id),
            ["com.coffic.gitok.git-backend.libgit2"]
        )
    }

    /// 设置窗口默认选中规则（回归测试）：全新启动后应选中 order 最小的入口。
    ///
    /// 背景：`addEntries` 会走 `registerEntries`，其"选中为空则锁定为当时列表
    /// 第一个"的语义会让**最先注册入口的插件**意外成为默认选中（Wakey/Lumi
    /// 均已踩坑并在各自内核启动后重置），共享装配引擎同样必须重置。
    func testSettingsDefaultsToFirstEntryByOrder() async throws {
        let kernel = try await makeKernel()
        let settings = try XCTUnwrap(kernel.resolveProvider((any SettingViewProviding).self))

        XCTAssertFalse(settings.entries.isEmpty, "设置入口应在内核启动后完成注册")
        let orders = settings.entries.map(\.order)
        XCTAssertEqual(orders, orders.sorted(), "entries must be sorted by order ascending")

        XCTAssertEqual(
            settings.selectedEntryID, settings.entries.first?.id,
            "默认应选中 \(settings.entries.first?.id ?? "nil")，实际为 \(settings.selectedEntryID ?? "nil")"
        )
    }

    /// GitOK 只加载白名单内的主题，加上 ProviderTheme 的内置基础外观。
    ///
    /// 断言具体 id 集合而非仅断言数量：数量断言挡不住「白名单被悄悄改成全量」
    /// 这类回归，id 集合能同时锁住白名单内容与裁剪结果。
    func testThemeCatalogIsRestrictedToWhitelist() async throws {
        let kernel = try await makeKernel()
        let theme = try XCTUnwrap(kernel.resolveProvider((any ThemeProviding).self))

        let expectedIDs: Set<String> = [
            // 白名单主题
            "lumi", "sky", "one-dark", "dracula", "vscode-light",
            // ProviderTheme 内置基础外观（不受白名单约束）
            "lumi-system", "lumi-dark", "lumi-light",
        ]

        XCTAssertEqual(Set(theme.themes.map(\.id)), expectedIDs)
        XCTAssertEqual(theme.themes.count, expectedIDs.count)
    }
}