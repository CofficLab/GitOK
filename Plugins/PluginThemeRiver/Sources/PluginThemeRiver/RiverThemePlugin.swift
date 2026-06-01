import GitOKCoreKit

public struct RiverThemePlugin: GitOKPlugin {
    public static let metadata = GitOKPluginMetadata(
        id: "ThemeRiverPlugin",
        displayName: "River Theme",
        description: "Flowing teal dark theme",
        iconName: "arrow.triangle.branch",
        order: 125,
        allowUserToggle: false,
        defaultEnabled: true,
        tableName: "ThemeRiver"
    )

    public static let shared = RiverThemePlugin()

    private init() {}

    @MainActor
    public func themeContributions() -> [GitOKUIThemeContribution] {
        [
            GitOKUIThemeContribution(
                sortKey: ThemeSortKey(pluginOrder: Self.metadata.order, themeId: RiverTheme.branchFlow.identifier),
                chromeTheme: RiverTheme.branchFlow,
                editorThemeId: RiverTheme.branchFlow.identifier
            ),
        ]
    }
}
