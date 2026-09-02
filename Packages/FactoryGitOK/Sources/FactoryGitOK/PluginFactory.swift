import KernelCore

#if os(macOS)
import PluginCommand
import PluginCommitList
import PluginLogoCoffic
import PluginLogoManager
import PluginProjects
import PluginSettingGeneral
import PluginSettingView
import PluginSettingsButton
import PluginSidebar
import PluginStatusBar
import PluginStorage
import PluginThemePack
#endif

/// GitOK 的专用插件目录。
///
/// 只装配 GitOK 宿主 UI 所需的基础插件（与 BookletMaker 同款基础目录，
/// 不含任何业务插件）。Lumi 的 LLM、Agent、项目、聊天等实验性插件
/// 不会进入这个应用的进程。
@MainActor
public struct DefaultPluginFactory: PluginFactory {
    public init() {}

    public func makePlugins() -> [any SuperPlugin] {
        [
            // 基础服务必须先于业务插件启动。
            try! StorageSuperPlugin(),
            CommandPlugin(),
            ProjectsPlugin(),
            SidebarPlugin(),
            CommitListPlugin(),
            SettingsButtonPlugin(),
            StatusBarPlugin(),
            PluginSettingView(),
            PluginLogoManager(),
            LogoCofficPlugin(),
            ThemePackPlugin(),
            SettingGeneralPlugin(),
        ]
    }
}
