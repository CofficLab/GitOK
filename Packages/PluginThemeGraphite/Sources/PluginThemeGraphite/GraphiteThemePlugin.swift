import GitOKPluginKit
import GitOKUI

public struct GraphiteThemePlugin: GitOKPackagedPlugin {
    public static let metadata = GitOKPluginMetadata(
        id: "ThemeGraphitePlugin",
        displayName: "Graphite Theme",
        description: "Neutral graphite dark theme",
        iconName: "square.grid.3x3",
        order: 134,
        allowUserToggle: false,
        defaultEnabled: true,
        tableName: "ThemeGraphite"
    )

    public static let shared = GraphiteThemePlugin()

    private init() {}

    @MainActor
    public func themeContributions() -> [GitOKUIThemeContribution] {
        [
            GitOKUIThemeContribution(
                sortKey: ThemeSortKey(pluginOrder: Self.metadata.order, themeId: GraphiteTheme.graphite.identifier),
                chromeTheme: GraphiteTheme.graphite,
                editorThemeId: GraphiteTheme.graphite.identifier
            ),
        ]
    }
}

