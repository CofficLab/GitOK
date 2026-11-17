import KernelCore

#if os(macOS)
import PluginActivityStatus
import PluginCommand
import PluginCloneRepository
import PluginCommitDetail
import PluginActivityHeatmap
import PluginProjectLanguages
import PluginCommitForm
import PluginCommitStatusBar
import PluginCommitToast
import PluginCommitList
import PluginRootView
import PluginRailView
import PluginGitDiff
import PluginGitLibGit2
import PluginGitBranchStatus
import PluginGitUnpushedStatus
import PluginGitUserSettings
import PluginGitNetworkSettings
import PluginGitRepositorySettings
import PluginGitCommitStyleSettings
import PluginGitStash
import PluginGitConflictResolver
import PluginFileInfo
import PluginAbout
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
import PluginGitWorktreePreheat
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
import PluginToolbar
import PluginWorktreeClean
import PluginWorktreeStatus
import PluginProjectReadme
import GitOKProviderRootView
#endif

/// GitOK 的专用插件目录。
///
/// 只装配 GitOK 宿主 UI 所需的基础插件（与 BookletMaker 同款基础目录，
/// 不含任何业务插件）。Lumi 的 LLM、Agent、项目、聊天等实验性插件
/// 不会进入这个应用的进程。
@MainActor
public struct DefaultPluginFactory: PluginFactory {
    public init() {}

    private func makeToastPlugin() -> ToastSuperPlugin {
        ToastSuperPlugin(
            overlayInstaller: { kernel, center in
                guard let rootView = kernel.resolveProvider((any RootViewProviding).self) else {
                    return
                }
                rootView.addOverlays([
                    RootOverlayItem(id: ToastSuperPlugin.overlayID, order: 10_000) { content in
                        ToastOverlay(content: content, center: center)
                    },
                ])
            },
            overlayUninstaller: { kernel in
                kernel.resolveProvider((any RootViewProviding).self)?
                    .removeOverlays(ids: [ToastSuperPlugin.overlayID])
            }
        )
    }

    public func makePlugins() -> [any SuperPlugin] {
        [
            // 基础服务必须先于业务插件启动。
            GitLibGit2Plugin(),
            try! StorageSuperPlugin(),
            CloneRepositoryPlugin(),
            RootViewPlugin(),
            RailViewPlugin(),
            PluginToolbar(),
            CommandPlugin(bundleID: "com.coffic.gitok.plugin.command"),
            ProjectsPlugin(),
            GitWorktreePreheatPlugin(),
            WorktreeStatusPlugin(),
            CommitListPlugin(),
            ActivityHeatmapPlugin(),
            ProjectLanguagesPlugin(),
            CommitDetailPlugin(),
            CommitFormPlugin(),
            GitDiffPlugin(),
            GitUserSettingsPlugin(),
            ProjectReadmePlugin(),
            WorktreeCleanPlugin(),
            GitNetworkSettingsPlugin(),
            GitRepositorySettingsPlugin(),
            GitCommitStyleSettingsPlugin(),
            GitStashPlugin(),
            GitConflictResolverPlugin(),
            FileInfoPlugin(),
            BannerPlugin(),
            IconPlugin(),
            // 「关于」入口（共享远程包 LumiPluginAbout，注入 GitOK 品牌配置）。
            AboutPlugin(
                id: "com.coffic.gitok.plugin.about",
                configuration: AboutConfiguration(
                    officialWebsiteURLString: "https://coffic.cn/gitok",
                    privacyPolicyURLString: "https://coffic.cn/privacy",
                    termsOfServiceURLString: "https://coffic.cn/terms"
                )
            ),
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
            makeToastPlugin(),
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
            PluginSettingView(id: "com.coffic.gitok.plugin.setting-view"),
            // Logo 插件来自共享包 LumiPluginLogos：注入 GitOK 品牌配置。
            // 插件 id 与历史一致，用户已保存的启用状态继续有效。
            PluginLogoManager(
                configuration: LogoManagerConfiguration(
                    pluginID: "com.coffic.gitok.plugin.logo-manager",
                    loggerSubsystem: "com.coffic.gitok.plugin.logo-manager",
                    policy: .disabled,
                    contributesAboutEntry: true,
                    appDisplayName: "GitOK"
                )
            ),
            LogoCofficPlugin(
                configuration: LogoCofficConfiguration(
                    policy: .disabled,
                    contributesAboutEntry: true,
                    appDisplayName: "GitOK"
                )
            ),
            ThemePackPlugin(
                id: "com.coffic.gitok.plugin.theme-pack",
                themeIDs: [
                    "lumi",          // 森林墨：低饱和暖色，跟随系统明暗（默认）
                    "sky",           // 清朗天蓝：通透浅底，跟随系统明暗
                    "one-dark",      // One Dark：经典开发者暗色
                    "dracula",       // Dracula：经典开发者暗色
                    "vscode-light",  // 固定亮色：低干扰底色
                ]
            ),
            SettingGeneralPlugin(),
            // GitOK 的插件策略全是 required / alwaysOn / disabled，没有用户可配置的
            // 插件；按默认策略入口会被隐藏。这里显式保留入口，设置页 UI 测试也
            // 依赖它存在。
            PluginPluginManager(id: "com.coffic.gitok.plugin.plugin-manager", entryVisibility: .always),
        ]
    }
}
