import GitOKCoreKit

public struct SpringThemePlugin: GitOKPlugin {
    public static let metadata = GitOKPluginMetadata(
        id: "ThemeSpringPlugin",
        displayName: "Spring Theme",
        description: "Fresh green light theme",
        iconName: "tree",
        order: 121,
        policy: .alwaysOn,
        tableName: "ThemeSpring"
    )

    public static let shared = SpringThemePlugin()

    private init() {}

    @MainActor
    public func themeContributions() -> [GitOKUIThemeContribution] {
        [
            GitOKUIThemeContribution(
                sortKey: ThemeSortKey(pluginOrder: Self.metadata.order, themeId: SpringTheme.worktree.identifier),
                chromeTheme: SpringTheme.worktree,
                editorThemeId: SpringTheme.worktree.identifier
            ),
        ]
    }
}
