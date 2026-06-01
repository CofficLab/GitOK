import GitOKCoreKit

public struct OneDarkThemePlugin: GitOKPlugin {
    public static let metadata = GitOKPluginMetadata(
        id: "ThemeOneDarkPlugin",
        displayName: "One Dark Theme",
        description: "Classic editor dark theme",
        iconName: "chevron.left.forwardslash.chevron.right",
        order: 136,
        allowUserToggle: false,
        defaultEnabled: true,
        tableName: "ThemeOneDark"
    )

    public static let shared = OneDarkThemePlugin()

    private init() {}

    @MainActor
    public func themeContributions() -> [GitOKUIThemeContribution] {
        [
            GitOKUIThemeContribution(
                sortKey: ThemeSortKey(pluginOrder: Self.metadata.order, themeId: OneDarkTheme.oneDark.identifier),
                chromeTheme: OneDarkTheme.oneDark,
                editorThemeId: OneDarkTheme.oneDark.identifier
            ),
        ]
    }
}

