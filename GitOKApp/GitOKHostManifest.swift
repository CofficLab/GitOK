import Foundation
import GitOKPluginRootView
import GitOKProviderRootView
import KernelCore
import LumiFactory
import ProviderGit
import ProviderRootView
import ProviderStatusBar
import ProviderStorage
import ProviderTheme
import ProviderToolbar
import ProviderWorkspaceScene
import SwiftUI

#if os(macOS)
import ProviderActivity
import ProviderCommand
import ProviderCommitForm
import ProviderRailView
import ProviderSidebar
#endif

/// GitOK 的宿主清单：与共享装配引擎（LumiFactory）之间的全部差异。
///
/// 装配流水线（基线 Provider → 迁移 → 启动 → 接线）由 `KernelAssembler`
/// 统一解释；这里只声明品牌身份、插件目录、存储/主题配置与两个钩子：
/// - `registerProviders`：基线未覆盖的 GitOK 域 Provider（Git / 工作区场景 /
///   侧边栏 / Rail / 命令 / 活动 / 提交表单），并把主题与根视图的持久化
///   目录指回插件数据目录（保住用户已有的主题选择与侧边栏宽度）；
/// - `wireKernel`：共享接线未覆盖的侧边栏 / Rail / 状态栏视图挂载。
///
/// AX 契约：GitOK 的 UI 测试依赖约 60 个后代标识，容器/内容级 id 会被
/// SwiftUI 传播遮蔽它们，故关闭内容标识、改用 1×1 就绪标记 overlay。
@MainActor
enum GitOKHostManifest {

    static func make(
        checkForUpdates: (@MainActor @Sendable () -> Void)? = nil
    ) -> HostManifest {
        HostManifest(
            identity: HostIdentity(
                appName: "GitOK",
                loggerSubsystem: "com.coffic.gitok",
                mainWindowID: "gitok.main",
                settingsWindowID: "gitok.settings",
                accessibilityPrefix: "gitok",
                mainWindowDefaultSize: CGSize(width: 1100, height: 760),
                settingsWindowDefaultSize: CGSize(width: 1000, height: 600)
            ),
            makePlugins: { GitOKPluginCatalog.makePlugins() },
            storage: HostStorageConfiguration(
                stateStorePluginID: "com.coffic.gitok.plugin.plugin-manager",
                dataRootDirectoryOverride: { uiTestDataRoot() }
            ),
            theme: HostThemeConfiguration(
                // 启动前预注册目录主题：加载页背景取自全局主题注册中心，
                // 晚注册会造成启动瞬间的明暗闪烁。
                catalogThemeIDs: ["lumi", "sky", "one-dark", "dracula", "vscode-light"],
                storageDirectoryName: "com.coffic.gitok.plugin.theme-pack"
            ),
            makeRootViewProvider: { GitOKRootViewProvider() },
            registerProviders: { kernel in
                try registerAppProviders(kernel: kernel)
            },
            wireKernel: { kernel in
                wireAppViews(kernel: kernel)
            },
            features: HostFeatures(
                // GitOK 有自己的 SettingsButtonPlugin（gitok.settings.button）。
                showsSettingsToolbarButton: false,
                openExternalPath: { kernel, url in
                    guard let path = ExternalOpenRequest.resolveDirectory(from: url) else { return }
                    GitOKExternalOpen.open(path, kernel: kernel)
                },
                checkForUpdates: checkForUpdates,
                appliesWindowContentIdentifiers: false,
                usesReadyMarkerOverlays: true
            )
        )
    }

    // MARK: - App Providers

    /// 基线未覆盖的 GitOK 域 Provider；在插件 boot 之前执行。
    private static func registerAppProviders(kernel: KernelCoreContainer) throws {
        let storage = try kernel.requireProvider((any StorageProviding).self)

        let workspaceScene = DefaultWorkspaceSceneProvider()
        try kernel.registerProvider((any WorkspaceSceneProviding).self, workspaceScene)

        // Git Provider 是稳定的业务入口；LibGit2Swift 实现由内置后端插件注册。
        let git = DefaultGitProvider()
        try kernel.registerProvider((any GitProviding).self, git)
        try kernel.registerProvider((any GitBackendRegistryProviding).self, git)

        // 基线主题 Provider 的默认存储目录与 GitOK 历史路径不同：
        // 指回插件数据目录，重新载入用户已保存的主题选择。
        if let theme = kernel.resolveProvider((any ThemeProviding).self) as? DefaultThemeProviding {
            theme.setStorageDirectory(
                storage.pluginDataDirectory(for: "com.coffic.gitok.plugin.theme-pack")
            )
        }

        // 根视图的 sidebar 宽度偏好由磁盘承载：装配阶段注入插件数据目录。
        if let root = kernel.resolveProvider((any RootViewProviding).self)
            as? GitOKProviderRootView.DefaultRootViewProvider {
            root.setStorageDirectory(
                storage.pluginDataDirectory(for: "com.coffic.gitok.plugin.root-view")
            )
        }

        kernel.resolveProvider((any ToolbarProviding).self)?.addToolbarItems([
            ToolbarItem(
                id: "workspace-scene-picker",
                title: appLocalization.string("Workspace"),
                placement: .leading,
                order: 0
            ) {
                WorkspaceScenePickerView(provider: workspaceScene)
            },
        ])

        try kernel.registerProvider((any StatusBarProviding).self, DefaultStatusBarProviding())

        #if os(macOS)
        try kernel.registerProvider((any SidebarProviding).self, DefaultSidebarProvider())
        try kernel.registerProvider((any RailViewProviding).self, DefaultRailViewProviding())
        try kernel.registerProvider((any CommandProviding).self, DefaultCommandProviding())

        let activity = DefaultActivityProvider()
        try kernel.registerProvider((any ActivityProviding).self, activity)

        // 提交 / 推送阶段上报到 Activity（状态栏活动指示）。
        let form = DefaultCommitFormProvider(git: git, storage: storage)
        form.activityReporter = { [weak activity] message in
            if let message {
                activity?.setActivity(message)
            } else {
                activity?.clearActivity()
            }
        }
        try kernel.registerProvider((any CommitFormProviding).self, form)
        #endif
    }

    // MARK: - Post-start Wiring

    /// 共享接线（工具栏 / 入口栏 / 内容）之外的 GitOK 视图挂载。
    private static func wireAppViews(kernel: KernelCoreContainer) {
        guard let rootView = kernel.resolveProvider((any RootViewProviding).self) else { return }

        if let statusBar = kernel.resolveProvider((any StatusBarProviding).self) {
            rootView.setStatusBarView(statusBar.makeStatusBarView())
        }
        #if os(macOS)
        if let sidebar = kernel.resolveProvider((any SidebarProviding).self) {
            rootView.setSidebarView(sidebar.makeSidebarView())
        }
        if let rail = kernel.resolveProvider((any RailViewProviding).self) {
            rootView.setRailView(rail.makeRailView())
            rootView.bindRailViewVisibility(to: rail)
            rootView.bindRailViewWidth(to: rail, onResize: rail.saveCurrentWidth)
        }
        #endif
    }

    // MARK: - UI Test Isolation

    private static func uiTestDataRoot() -> URL? {
        #if DEBUG
        return ProcessInfo.processInfo.environment["GITOK_UI_TEST_DATA_ROOT"]
            .flatMap { path in
                path.isEmpty ? nil : URL(fileURLWithPath: path, isDirectory: true)
            }
        #else
        return nil
        #endif
    }
}