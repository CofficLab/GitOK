import GitOKCoreKit
import ActivityStatusPlugin
import AutoPushPlugin
import BannerPlugin
import BannerTabPlugin
import BranchPlugin
import CleanStatusPlugin
import CommitPlugin
import ConflictResolverPlugin
import FileInfoPlugin
import GitDetailPlugin
import GitIgnorePlugin
import GitLFSPlugin
import GitPullPlugin
import GitPushPlugin
import GitSyncPlugin
import GitTabPlugin
import GitWatcherPlugin
import IconPlugin
import IconTabPlugin
import LicensePlugin
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
import ProjectPickerPlugin
import ReadmePlugin
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
    public static let hasDefaultAdapters = true

    /// Register default plugin adapters for all packaged plugins.
    ///
    /// Each plugin's own policy still decides whether it is registered at runtime.
    @MainActor
    public static func registerDefaultAdapters(
        adapterFactory: any GitOKPluginAdapterFactory,
        _ register: (any SuperPlugin) -> Void
    ) {
        if ActivityStatusPlugin.shouldRegister { register(adapterFactory.makeAdapter(for: ActivityStatusPlugin.shared)) }
        if AutoPushPlugin.shouldRegister { register(adapterFactory.makeAdapter(for: AutoPushPlugin.shared)) }
        if BannerPlugin.shouldRegister { register(adapterFactory.makeAdapter(for: BannerPlugin.shared)) }
        if BannerTabPlugin.shouldRegister { register(adapterFactory.makeAdapter(for: BannerTabPlugin.shared)) }
        if BranchPlugin.shouldRegister { register(adapterFactory.makeAdapter(for: BranchPlugin.shared)) }
        if CleanStatusPlugin.shouldRegister { register(adapterFactory.makeAdapter(for: CleanStatusPlugin.shared)) }
        if CommitPlugin.shouldRegister { register(adapterFactory.makeAdapter(for: CommitPlugin.shared)) }
        if ConflictResolverPlugin.shouldRegister { register(adapterFactory.makeAdapter(for: ConflictResolverPlugin.shared)) }
        if FileInfoPlugin.shouldRegister { register(adapterFactory.makeAdapter(for: FileInfoPlugin.shared)) }
        if GitDetailPlugin.shouldRegister { register(adapterFactory.makeAdapter(for: GitDetailPlugin.shared)) }
        if GitIgnorePlugin.shouldRegister { register(adapterFactory.makeAdapter(for: GitIgnorePlugin.shared)) }
        if GitLFSPlugin.shouldRegister { register(adapterFactory.makeAdapter(for: GitLFSPlugin.shared)) }
        if GitPullPlugin.shouldRegister { register(adapterFactory.makeAdapter(for: GitPullPlugin.shared)) }
        if GitPushPlugin.shouldRegister { register(adapterFactory.makeAdapter(for: GitPushPlugin.shared)) }
        if GitSyncPlugin.shouldRegister { register(adapterFactory.makeAdapter(for: GitSyncPlugin.shared)) }
        if GitTabPlugin.shouldRegister { register(adapterFactory.makeAdapter(for: GitTabPlugin.shared)) }
        if GitWatcherPlugin.shouldRegister { register(adapterFactory.makeAdapter(for: GitWatcherPlugin.shared)) }
        if IconPlugin.shouldRegister { register(adapterFactory.makeAdapter(for: IconPlugin.shared)) }
        if IconTabPlugin.shouldRegister { register(adapterFactory.makeAdapter(for: IconTabPlugin.shared)) }
        if LicensePlugin.shouldRegister { register(adapterFactory.makeAdapter(for: LicensePlugin.shared)) }
        if OpenAntigravityPlugin.shouldRegister { register(adapterFactory.makeAdapter(for: OpenAntigravityPlugin.shared)) }
        if OpenCursorPlugin.shouldRegister { register(adapterFactory.makeAdapter(for: OpenCursorPlugin.shared)) }
        if OpenFinderPlugin.shouldRegister { register(adapterFactory.makeAdapter(for: OpenFinderPlugin.shared)) }
        if OpenGitHubDesktopPlugin.shouldRegister { register(adapterFactory.makeAdapter(for: OpenGitHubDesktopPlugin.shared)) }
        if OpenKiroPlugin.shouldRegister { register(adapterFactory.makeAdapter(for: OpenKiroPlugin.shared)) }
        if OpenRemotePlugin.shouldRegister { register(adapterFactory.makeAdapter(for: OpenRemotePlugin.shared)) }
        if OpenTerminalPlugin.shouldRegister { register(adapterFactory.makeAdapter(for: OpenTerminalPlugin.shared)) }
        if OpenTraePlugin.shouldRegister { register(adapterFactory.makeAdapter(for: OpenTraePlugin.shared)) }
        if OpenVSCodePlugin.shouldRegister { register(adapterFactory.makeAdapter(for: OpenVSCodePlugin.shared)) }
        if OpenXcodePlugin.shouldRegister { register(adapterFactory.makeAdapter(for: OpenXcodePlugin.shared)) }
        if ProjectPickerPlugin.shouldRegister { register(adapterFactory.makeAdapter(for: ProjectPickerPlugin.shared)) }
        if ReadmePlugin.shouldRegister { register(adapterFactory.makeAdapter(for: ReadmePlugin.shared)) }
        if RemoteRepositoryPlugin.shouldRegister { register(adapterFactory.makeAdapter(for: RemoteRepositoryPlugin.shared)) }
        if SettingsButtonPlugin.shouldRegister { register(adapterFactory.makeAdapter(for: SettingsButtonPlugin.shared)) }
        if SmartMergePlugin.shouldRegister { register(adapterFactory.makeAdapter(for: SmartMergePlugin.shared)) }
        if StashPlugin.shouldRegister { register(adapterFactory.makeAdapter(for: StashPlugin.shared)) }
        if SubmodulePlugin.shouldRegister { register(adapterFactory.makeAdapter(for: SubmodulePlugin.shared)) }
        if AuroraThemePlugin.shouldRegister { register(adapterFactory.makeAdapter(for: AuroraThemePlugin.shared)) }
        if DraculaThemePlugin.shouldRegister { register(adapterFactory.makeAdapter(for: DraculaThemePlugin.shared)) }
        if EmberThemePlugin.shouldRegister { register(adapterFactory.makeAdapter(for: EmberThemePlugin.shared)) }
        if GitHubLightThemePlugin.shouldRegister { register(adapterFactory.makeAdapter(for: GitHubLightThemePlugin.shared)) }
        if GitOKThemePlugin.shouldRegister { register(adapterFactory.makeAdapter(for: GitOKThemePlugin.shared)) }
        if GlacierThemePlugin.shouldRegister { register(adapterFactory.makeAdapter(for: GlacierThemePlugin.shared)) }
        if GraphiteThemePlugin.shouldRegister { register(adapterFactory.makeAdapter(for: GraphiteThemePlugin.shared)) }
        if HarborThemePlugin.shouldRegister { register(adapterFactory.makeAdapter(for: HarborThemePlugin.shared)) }
        if MatrixThemePlugin.shouldRegister { register(adapterFactory.makeAdapter(for: MatrixThemePlugin.shared)) }
        if MidnightThemePlugin.shouldRegister { register(adapterFactory.makeAdapter(for: MidnightThemePlugin.shared)) }
        if MountainThemePlugin.shouldRegister { register(adapterFactory.makeAdapter(for: MountainThemePlugin.shared)) }
        if NebulaThemePlugin.shouldRegister { register(adapterFactory.makeAdapter(for: NebulaThemePlugin.shared)) }
        if OneDarkThemePlugin.shouldRegister { register(adapterFactory.makeAdapter(for: OneDarkThemePlugin.shared)) }
        if OrchardThemePlugin.shouldRegister { register(adapterFactory.makeAdapter(for: OrchardThemePlugin.shared)) }
        if RiverThemePlugin.shouldRegister { register(adapterFactory.makeAdapter(for: RiverThemePlugin.shared)) }
        if SpringThemePlugin.shouldRegister { register(adapterFactory.makeAdapter(for: SpringThemePlugin.shared)) }
        if ThemeStatusBarPlugin.shouldRegister { register(adapterFactory.makeAdapter(for: ThemeStatusBarPlugin.shared)) }
        if SummerThemePlugin.shouldRegister { register(adapterFactory.makeAdapter(for: SummerThemePlugin.shared)) }
        if WinterThemePlugin.shouldRegister { register(adapterFactory.makeAdapter(for: WinterThemePlugin.shared)) }
        if XcodeLightThemePlugin.shouldRegister { register(adapterFactory.makeAdapter(for: XcodeLightThemePlugin.shared)) }
        if UnpushedStatusPlugin.shouldRegister { register(adapterFactory.makeAdapter(for: UnpushedStatusPlugin.shared)) }
    }
}
