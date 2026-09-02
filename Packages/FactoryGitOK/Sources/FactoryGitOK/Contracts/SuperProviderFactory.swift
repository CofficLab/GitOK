import KernelCore
import ProviderContentView
import ProviderDocsView
import ProviderRailView
import ProviderRootView
import ProviderSettingView
import ProviderStorage
import ProviderTheme
import ProviderToolbar

#if os(macOS)
import ProviderActivityBar
import ProviderCommand
import ProviderLogo
#endif

/// GitOK 宿主需要的最小 Provider 装配契约。
///
/// 与 Lumi 的专用宿主一致：只装配 GitOK 工作流所需的 Provider，
/// 不包含 Lumi 的聊天、Agent、LLM、项目和网络能力。
@MainActor
public protocol ProviderFactory {
    func makeStorageProvider() -> any StorageProviding
    func makeThemeProvider() -> any ThemeProviding
    func makeContentViewProvider() -> any ContentViewProviding
    func makeDocsViewProvider() -> any DocsViewProviding
    func makeToolbarProvider() -> any ToolbarProviding
    func makeRootViewProvider() -> any RootViewProviding

    #if os(macOS)
    func makeLogoProvider() -> any LogoProviding
    func makeActivityBarProvider() -> any ActivityBarProviding
    func makeRailViewProvider() -> any RailViewProviding
    func makeCommandProvider() -> any CommandProviding
    #endif

    func makeSettingViewProvider() -> any SettingViewProviding
    func registerProviders(into kernel: KernelCoreContainer) throws
}
