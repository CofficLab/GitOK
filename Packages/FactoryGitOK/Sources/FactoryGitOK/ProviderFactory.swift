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

#if os(macOS)
import ProviderCommand
import ProviderCommitDetail
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

        try kernel.registerProvider((any ContentViewProviding).self, makeContentViewProvider())
        try kernel.registerProvider((any DocsViewProviding).self, makeDocsViewProvider())
        try kernel.registerProvider((any ToolbarProviding).self, makeToolbarProvider())
        try kernel.registerProvider((any StatusBarProviding).self, makeStatusBarProvider())
        try kernel.registerProvider((any RootViewProviding).self, makeRootViewProvider())
        try kernel.registerProvider((any SettingViewProviding).self, makeSettingViewProvider())

        #if os(macOS)
        try kernel.registerProvider((any LogoProviding).self, makeLogoProvider())
        try kernel.registerProvider((any SidebarProviding).self, makeSidebarProvider())
        try kernel.registerProvider((any RailViewProviding).self, makeRailViewProvider())
        try kernel.registerProvider((any CommandProviding).self, makeCommandProvider())
        try kernel.registerProvider((any CommitDetailProviding).self, makeCommitDetailProvider())
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
        DefaultSidebarProviding()
    }

    public func makeRailViewProvider() -> any RailViewProviding {
        DefaultRailViewProviding()
    }

    public func makeCommandProvider() -> any CommandProviding {
        DefaultCommandProviding()
    }

    public func makeCommitDetailProvider() -> any CommitDetailProviding {
        DefaultCommitDetailProvider()
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
