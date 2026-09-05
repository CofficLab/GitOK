import KernelCore
import ProviderContentView
import ProviderDocsView
import ProviderRootView
import ProviderSettingView
import ProviderStatusBar
import ProviderStorage
import ProviderTheme
import ProviderToast
import ProviderToolbar
import ProviderWorkspaceScene

#if os(macOS)
import ProviderActivity
import ProviderCommand
import ProviderCommitForm
import ProviderLogo
import ProviderPluginManaging
import ProviderRailView
import ProviderSidebar
#endif

/// GitOK 的最小 Provider 装配。
@MainActor
public struct DefaultProviderFactory: ProviderFactory {
    public init() {}

    public func makeStorageProvider() -> any StorageProviding {
        DefaultStorageProvider()
    }

    public func makeWorkspaceSceneProvider() -> any WorkspaceSceneProviding {
        DefaultWorkspaceSceneProvider()
    }

    public func makeThemeProvider() -> any ThemeProviding {
        DefaultThemeProviding()
    }

    public func makeContentViewProvider() -> any ContentViewProviding {
        DefaultContentViewProviding()
    }

    public func makeDocsViewProvider() -> any DocsViewProviding {
        DefaultDocsViewProviding()
    }

    public func makeToolbarProvider() -> any ToolbarProviding {
        DefaultToolbarProviding()
    }

    public func makeStatusBarProvider() -> any StatusBarProviding {
        DefaultStatusBarProviding()
    }

    public func makeRootViewProvider() -> any RootViewProviding {
        DefaultRootViewProvider()
    }

    public func makeSettingViewProvider() -> any SettingViewProviding {
        DefaultSettingViewProviding()
    }

    public func registerProviders(into kernel: KernelCoreContainer) throws {
        let storage = makeStorageProvider()
        try kernel.registerProvider((any StorageProviding).self, storage)

        let workspaceScene = makeWorkspaceSceneProvider()
        try kernel.registerProvider((any WorkspaceSceneProviding).self, workspaceScene)

        // 插件启用状态仍由宿主统一持久化；GitOK 插件本身是 required，
        // 其他未来加入的插件则继续遵循 KernelCore 的普通策略。
        kernel.stateStore = PluginEnabledStateStore(
            pluginDirectory: storage.pluginDataDirectory(for: "PluginManager")
        )

        let theme = makeThemeProvider()
        if let defaultTheme = theme as? DefaultThemeProviding {
            defaultTheme.setStorageDirectory(
                storage.pluginDataDirectory(for: "ThemeManager")
            )
        }
        try kernel.registerProvider((any ThemeProviding).self, theme)

        let contentView = makeContentViewProvider()
        contentView.bindWorkspaceSceneProvider(workspaceScene)
        try kernel.registerProvider((any ContentViewProviding).self, contentView)
        try kernel.registerProvider((any DocsViewProviding).self, makeDocsViewProvider())

        let toolbar = makeToolbarProvider()
        toolbar.bindWorkspaceSceneProvider(workspaceScene)
        toolbar.addToolbarItems([
            ToolbarItem(
                id: "workspace-scene-picker",
                title: LumiPluginLocalization.string("Workspace", bundle: .module),
                placement: .leading,
                order: 0
            ) {
                WorkspaceScenePickerView(provider: workspaceScene)
            },
        ])
        try kernel.registerProvider((any ToolbarProviding).self, toolbar)

        let statusBar = makeStatusBarProvider()
        statusBar.bindWorkspaceSceneProvider(workspaceScene)
        try kernel.registerProvider((any StatusBarProviding).self, statusBar)
        try kernel.registerProvider((any RootViewProviding).self, makeRootViewProvider())
        try kernel.registerProvider((any SettingViewProviding).self, makeSettingViewProvider())

        #if os(macOS)
        try kernel.registerProvider((any LogoProviding).self, makeLogoProvider())
        let sidebar = makeSidebarProvider()
        sidebar.bindWorkspaceSceneProvider(workspaceScene)
        try kernel.registerProvider((any SidebarProviding).self, sidebar)

        let rail = makeRailViewProvider()
        rail.bindWorkspaceSceneProvider(workspaceScene)
        try kernel.registerProvider((any RailViewProviding).self, rail)
        try kernel.registerProvider((any CommandProviding).self, makeCommandProvider())
        try kernel.registerProvider((any ActivityProviding).self, makeActivityProvider())
        try kernel.registerProvider(
            (any CommitFormProviding).self,
            makeCommitFormProvider(activity: kernel.resolveProvider((any ActivityProviding).self))
        )
        try kernel.registerProvider((any ToastProviding).self, makeToastProvider())
        let pluginManaging = makePluginManagingProvider()
        if let concrete = pluginManaging as? DefaultPluginManager {
            concrete.attach(kernel: kernel)
        }
        try kernel.registerProvider((any PluginManaging).self, pluginManaging)
        #endif
    }
}

#if os(macOS)
extension DefaultProviderFactory {
    public func makeLogoProvider() -> any LogoProviding {
        DefaultLogoProviding()
    }

    public func makeSidebarProvider() -> any SidebarProviding {
        DefaultSidebarProvider()
    }

    public func makeRailViewProvider() -> any RailViewProviding {
        DefaultRailViewProviding()
    }

    public func makeCommandProvider() -> any CommandProviding {
        DefaultCommandProviding()
    }

    public func makeActivityProvider() -> any ActivityProviding {
        DefaultActivityProvider()
    }

    /// 提交表单 Provider：把提交 / 推送阶段上报到 Activity 提供者（状态栏活动指示）。
    public func makeCommitFormProvider(activity: (any ActivityProviding)?) -> any CommitFormProviding {
        let form = DefaultCommitFormProvider()
        if let activity {
            form.activityReporter = { [weak activity] message in
                if let message {
                    activity?.setActivity(message)
                } else {
                    activity?.clearActivity()
                }
            }
        }
        return form
    }

    /// 产出 `ToastProviding` 实现（默认 no-op；由 PluginToast 在 onBoot 替换为真实状态机）。
    public func makeToastProvider() -> any ToastProviding {
        DefaultToastProviding()
    }

    public func makePluginManagingProvider() -> any PluginManaging {
        DefaultPluginManager()
    }
}
#endif
