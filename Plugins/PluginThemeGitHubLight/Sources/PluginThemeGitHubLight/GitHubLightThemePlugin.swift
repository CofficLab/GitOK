import GitOKCoreKit
import GitOKUI

public struct GitHubLightThemePlugin: GitOKPlugin {
    public static let metadata = GitOKPluginMetadata(
        id: "ThemeGitHubLightPlugin",
        displayName: "GitHub Light Theme",
        description: "GitHub-inspired light theme",
        iconName: "globe",
        order: 138,
        allowUserToggle: false,
        defaultEnabled: true,
        tableName: "ThemeGitHubLight"
    )

    public static let shared = GitHubLightThemePlugin()

    private init() {}

    @MainActor
    public func themeContributions() -> [GitOKUIThemeContribution] {
        [
            GitOKUIThemeContribution(
                sortKey: ThemeSortKey(pluginOrder: Self.metadata.order, themeId: GitHubLightTheme.githubLight.identifier),
                chromeTheme: GitHubLightTheme.githubLight,
                editorThemeId: GitHubLightTheme.githubLight.identifier
            ),
        ]
    }
}
