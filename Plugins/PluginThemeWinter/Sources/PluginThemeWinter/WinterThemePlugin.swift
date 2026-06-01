import GitOKCoreKit

public struct WinterThemePlugin: GitOKPlugin {
    public static let metadata = GitOKPluginMetadata(
        id: "ThemeWinterPlugin",
        displayName: "Winter Theme",
        description: "Cool minimal light theme",
        iconName: "scope",
        order: 133,
        policy: .alwaysOn,
        tableName: "ThemeWinter"
    )

    public static let shared = WinterThemePlugin()

    private init() {}

    @MainActor
    public func themeContributions() -> [GitOKUIThemeContribution] {
        [
            GitOKUIThemeContribution(
                sortKey: ThemeSortKey(pluginOrder: Self.metadata.order, themeId: WinterTheme.focus.identifier),
                chromeTheme: WinterTheme.focus,
                editorThemeId: WinterTheme.focus.identifier
            ),
        ]
    }
}

