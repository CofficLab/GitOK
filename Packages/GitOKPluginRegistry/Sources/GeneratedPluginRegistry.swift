import GitOKCoreKit
import AboutSettingsPlugin
import ActivityStatusPlugin
import AppearanceSettingsPlugin
import GitAutoPushPlugin
import BannerPlugin
import GitBranchPlugin
import GitCleanStatusPlugin
import GitCommitListPlugin
import GitCommitStyleSettingsPlugin
import GitConflictResolverPlugin
import DiagnosticsSettingsPlugin
import FileInfoPlugin
import GitNetworkSettingsPlugin
import GitUserSettingsPlugin
import GitDetailPlugin
import GitIgnorePlugin
import GitLFSPlugin
import GitWatcherPlugin
import IconPlugin
import LicensePlugin
import OnboardingPlugin
import OpenAntigravityPlugin
import OpenCursorPlugin
import OpenFinderPlugin
import OpenGitHubDesktopPlugin
import OpenKiroPlugin
import OpenLumiPlugin
import OpenRemotePlugin
import OpenTerminalPlugin
import OpenTraePlugin
import OpenVSCodePlugin
import OpenXcodePlugin
import ProjectsPlugin
import ProjectPickerPlugin
import ReadmePlugin
import GitRepositorySettingsPlugin
import GitRemoteRepositoryPlugin
import SettingsButtonPlugin
import GitMergePlugin
import GitStashPlugin
import GitSubmodulePlugin
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
import GitUnpushedStatusPlugin
import GitWorkingStatePlugin

/// Central plugin registry.
///
/// Add new packaged plugins here explicitly when they should be available to GitOK.
public enum GeneratedPluginRegistry {
    public static let plugins: [any GitOKPlugin.Type] = [
        AboutSettingsPlugin.self,
        ActivityStatusPlugin.self,
        AppearanceSettingsPlugin.self,
        GitAutoPushPlugin.self,
        BannerPlugin.self,
        GitBranchPlugin.self,
        GitCleanStatusPlugin.self,
        GitCommitListPlugin.self,
        GitCommitStyleSettingsPlugin.self,
        GitConflictResolverPlugin.self,
        DiagnosticsSettingsPlugin.self,
        FileInfoPlugin.self,
        GitDetailPlugin.self,
        GitNetworkSettingsPlugin.self,
        GitUserSettingsPlugin.self,
        GitIgnorePlugin.self,
        GitLFSPlugin.self,
        GitWatcherPlugin.self,
        IconPlugin.self,
        LicensePlugin.self,
        OpenAntigravityPlugin.self,
        OpenCursorPlugin.self,
        OpenFinderPlugin.self,
        OpenGitHubDesktopPlugin.self,
        OpenKiroPlugin.self,
        OpenLumiPlugin.self,
        OpenRemotePlugin.self,
        OpenTerminalPlugin.self,
        OpenTraePlugin.self,
        OpenVSCodePlugin.self,
        OpenXcodePlugin.self,
        OnboardingPlugin.self,
        ProjectsPlugin.self,
        ProjectPickerPlugin.self,
        ReadmePlugin.self,
        GitRepositorySettingsPlugin.self,
        GitRemoteRepositoryPlugin.self,
        SettingsButtonPlugin.self,
        GitMergePlugin.self,
        GitStashPlugin.self,
        GitSubmodulePlugin.self,
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
        GitUnpushedStatusPlugin.self,
        GitWorkingStatePlugin.self,
    ]

    @MainActor
    public static func registerAll(into runtime: GitOKPluginRuntime) {
        for plugin in plugins where plugin.shouldRegister {
            runtime.register(plugin)
        }
    }
}
