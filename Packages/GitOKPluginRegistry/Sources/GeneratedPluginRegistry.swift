import GitOKCoreKit
import AboutSettingsPlugin
import ActivityStatusPlugin
import AppearanceSettingsPlugin
import AutoPushPlugin
import BannerPlugin
import BannerTabPlugin
import BranchPlugin
import CleanStatusPlugin
import CommitPlugin
import CommitStyleSettingsPlugin
import ConflictResolverPlugin
import DiagnosticsSettingsPlugin
import FileInfoPlugin
import GitNetworkSettingsPlugin
import GitUserSettingsPlugin
import GitDetailPlugin
import GitIgnorePlugin
import GitLFSPlugin
import GitTabPlugin
import GitWatcherPlugin
import IconPlugin
import IconTabPlugin
import LicensePlugin
import OnboardingPlugin
import OpenAntigravityPlugin
import OpenCursorPlugin
import OpenFinderPlugin
import OpenGitHubDesktopPlugin
import OpenKiroPlugin
import OpenRemotePlugin
import OpenTerminalPlugin
import OpenTraePlugin
import OpenVSCodePlugin
import OpenXcodePlugin
import ProjectsPlugin
import ProjectPickerPlugin
import ReadmePlugin
import RepositorySettingsPlugin
import RemoteRepositoryPlugin
import SettingsButtonPlugin
import SmartMergePlugin
import StashPlugin
import SubmodulePlugin
import ThemeAuroraPlugin
import ThemeDraculaPlugin
import ThemeEmberPlugin
import ThemeGitHubLightPlugin
import ThemeGitOKPlugin
import ThemeGlacierPlugin
import ThemeGraphitePlugin
import ThemeHarborPlugin
import ThemeMatrixPlugin
import ThemeMidnightPlugin
import ThemeMountainPlugin
import ThemeNebulaPlugin
import ThemeOneDarkPlugin
import ThemeOrchardPlugin
import ThemeRiverPlugin
import ThemeSpringPlugin
import ThemeStatusBarPlugin
import ThemeSummerPlugin
import ThemeWinterPlugin
import ThemeXcodeLightPlugin
import UnpushedStatusPlugin

/// Central plugin registry.
///
/// Add new packaged plugins here explicitly when they should be available to GitOK.
public enum GeneratedPluginRegistry {
    public static let plugins: [any GitOKPlugin.Type] = [
        AboutSettingsPlugin.self,
        ActivityStatusPlugin.self,
        AppearanceSettingsPlugin.self,
        AutoPushPlugin.self,
        BannerPlugin.self,
        BannerTabPlugin.self,
        BranchPlugin.self,
        CleanStatusPlugin.self,
        CommitPlugin.self,
        CommitStyleSettingsPlugin.self,
        ConflictResolverPlugin.self,
        DiagnosticsSettingsPlugin.self,
        FileInfoPlugin.self,
        GitDetailPlugin.self,
        GitNetworkSettingsPlugin.self,
        GitUserSettingsPlugin.self,
        GitIgnorePlugin.self,
        GitLFSPlugin.self,
        GitTabPlugin.self,
        GitWatcherPlugin.self,
        IconPlugin.self,
        IconTabPlugin.self,
        LicensePlugin.self,
        OpenAntigravityPlugin.self,
        OpenCursorPlugin.self,
        OpenFinderPlugin.self,
        OpenGitHubDesktopPlugin.self,
        OpenKiroPlugin.self,
        OpenRemotePlugin.self,
        OpenTerminalPlugin.self,
        OpenTraePlugin.self,
        OpenVSCodePlugin.self,
        OpenXcodePlugin.self,
        OnboardingPlugin.self,
        ProjectsPlugin.self,
        ProjectPickerPlugin.self,
        ReadmePlugin.self,
        RepositorySettingsPlugin.self,
        RemoteRepositoryPlugin.self,
        SettingsButtonPlugin.self,
        SmartMergePlugin.self,
        StashPlugin.self,
        SubmodulePlugin.self,
        AuroraThemePlugin.self,
        DraculaThemePlugin.self,
        EmberThemePlugin.self,
        GitHubLightThemePlugin.self,
        GitOKThemePlugin.self,
        GlacierThemePlugin.self,
        GraphiteThemePlugin.self,
        HarborThemePlugin.self,
        MatrixThemePlugin.self,
        MidnightThemePlugin.self,
        MountainThemePlugin.self,
        NebulaThemePlugin.self,
        OneDarkThemePlugin.self,
        OrchardThemePlugin.self,
        RiverThemePlugin.self,
        SpringThemePlugin.self,
        ThemeStatusBarPlugin.self,
        SummerThemePlugin.self,
        WinterThemePlugin.self,
        XcodeLightThemePlugin.self,
        UnpushedStatusPlugin.self,
    ]

    @MainActor
    public static func registerAll(into runtime: GitOKPluginRuntime) {
        for plugin in plugins where plugin.shouldRegister {
            runtime.register(plugin)
        }
    }
}
