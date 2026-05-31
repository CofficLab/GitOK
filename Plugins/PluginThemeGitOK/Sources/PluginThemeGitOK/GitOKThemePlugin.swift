import GitOKPluginKit
import GitOKUI

public struct GitOKThemePlugin: GitOKPackagedPlugin {
    public static let metadata = GitOKPluginMetadata(
        id: "ThemeGitOKPlugin",
        displayName: "GitOK Theme",
        description: "Default GitOK dark theme",
        iconName: "folder.badge.gearshape",
        order: 120,
        allowUserToggle: false,
        defaultEnabled: true,
        tableName: "ThemeGitOK"
    )

    public static let shared = GitOKThemePlugin()

    private init() {}

    @MainActor
    public func themeContributions() -> [GitOKUIThemeContribution] {
        [
            GitOKUIThemeContribution(
                sortKey: ThemeSortKey(pluginOrder: Self.metadata.order, themeId: GitOKTheme.repository.identifier),
                chromeTheme: GitOKTheme.repository,
                editorThemeId: GitOKTheme.repository.identifier
            ),
        ]
    }
}
