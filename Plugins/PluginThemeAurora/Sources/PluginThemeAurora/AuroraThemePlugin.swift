import GitOKCoreKit

public struct AuroraThemePlugin: GitOKPlugin {
    public static let metadata = GitOKPluginMetadata(
        id: "ThemeAuroraPlugin",
        displayName: "Aurora Theme",
        description: "Deep cyan night theme",
        iconName: "point.3.connected.trianglepath.dotted",
        order: 122,
        allowUserToggle: false,
        defaultEnabled: true,
        tableName: "ThemeAurora"
    )

    public static let shared = AuroraThemePlugin()

    private init() {}

    @MainActor
    public func themeContributions() -> [GitOKUIThemeContribution] {
        [
            GitOKUIThemeContribution(
                sortKey: ThemeSortKey(pluginOrder: Self.metadata.order, themeId: AuroraTheme.commitGraph.identifier),
                chromeTheme: AuroraTheme.commitGraph,
                editorThemeId: AuroraTheme.commitGraph.identifier
            ),
        ]
    }
}
