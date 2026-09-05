import KernelCore

#if os(macOS)
import PluginActivityStatus
import PluginCommand
import PluginCommitDetail
import PluginCommitForm
import PluginCommitStatusBar
import PluginCommitToast
import PluginCommitList
import PluginCloneRepository
import PluginRootView
import PluginGitDiff
import PluginGitBranchStatus
import PluginGitUnpushedStatus
import PluginGitUserSettings
import PluginGitNetworkSettings
import PluginGitRepositorySettings
import PluginGitCommitStyleSettings
import PluginGitStash
import PluginGitConflictResolver
import PluginFileInfo
import PluginAboutSettings
import PluginBanner
import PluginIcon
import PluginGitIgnore
import PluginGitAutoPush
import PluginLicense
import PluginGitRemoteRepository
import PluginDiagnosticsSettings
import PluginGitSmartMerge
import PluginGitLFS
import PluginGitSubmodule
import PluginGitRepositoryWatch
import PluginLogoCoffic
import PluginLogoManager
import PluginOpenAntigravity
import PluginOpenCursor
import PluginOpenFinder
import PluginOpenGitHubDesktop
import PluginOpenKiro
import PluginOpenLumi
import PluginOpenRemote
import PluginOpenTerminal
import PluginOpenTrae
import PluginOpenVSCode
import PluginOpenXcode
import PluginPluginManager
import PluginProjects
import PluginSettingGeneral
import PluginSettingView
import PluginSettingsButton
import PluginSidebarToggle
import PluginStatusBar
import PluginStorage
import PluginToast
import PluginThemePack
import PluginWorktreeClean
import PluginWorktreeStatus
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
            RootViewPlugin(),
            CommandPlugin(),
            ProjectsPlugin(),
            CloneRepositoryPlugin(),
            WorktreeStatusPlugin(),
            CommitListPlugin(),
            CommitDetailPlugin(),
            CommitFormPlugin(),
            GitDiffPlugin(),
            GitUserSettingsPlugin(),
            WorktreeCleanPlugin(),
            GitNetworkSettingsPlugin(),
            GitRepositorySettingsPlugin(),
            GitCommitStyleSettingsPlugin(),
            GitStashPlugin(),
            GitConflictResolverPlugin(),
            FileInfoPlugin(),
            BannerPlugin(),
            IconPlugin(),
            AboutSettingsPlugin(),
            GitIgnorePlugin(),
            GitAutoPushPlugin(),
            LicensePlugin(),
            GitRemoteRepositoryPlugin(),
            DiagnosticsSettingsPlugin(),
            GitSmartMergePlugin(),
            GitLFSPlugin(),
            GitSubmodulePlugin(),
            GitRepositoryWatchPlugin(),
            SettingsButtonPlugin(),
            SidebarTogglePlugin(),
            StatusBarPlugin(),
            ActivityStatusPlugin(),
            GitBranchStatusPlugin(),
            GitUnpushedStatusPlugin(),
            ToastSuperPlugin(),
            CommitToastPlugin(),
            CommitStatusBarPlugin(),
            OpenFinderPlugin(),
            OpenTerminalPlugin(),
            OpenVSCodePlugin(),
            OpenCursorPlugin(),
            OpenXcodePlugin(),
            OpenTraePlugin(),
            OpenAntigravityPlugin(),
            OpenGitHubDesktopPlugin(),
            OpenKiroPlugin(),
            OpenLumiPlugin(),
            OpenRemotePlugin(),
            PluginSettingView(),
            PluginLogoManager(),
            LogoCofficPlugin(),
            ThemePackPlugin(),
            SettingGeneralPlugin(),
            PluginPluginManager(),
        ]
    }
}
