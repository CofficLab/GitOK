import Foundation
import GitOKCoreKit

public struct GitHubLightThemePlugin: GitOKPlugin {
    public static let metadata = GitOKPluginMetadata(
        id: "ThemeGitHubLightPlugin",
        displayName: GitHubLightThemePluginLocalization.string("GitHub Light Theme"),
        description: GitHubLightThemePluginLocalization.string("GitHub-inspired light theme"),
        iconName: "globe",
        order: 138,
        policy: .alwaysOn,
        tableName: GitHubLightThemePluginLocalization.table
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


public enum GitHubLightThemePluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
