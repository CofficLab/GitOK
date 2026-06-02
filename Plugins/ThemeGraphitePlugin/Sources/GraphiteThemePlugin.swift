import Foundation
import GitOKCoreKit

public struct GraphiteThemePlugin: GitOKPlugin {
    public static let metadata = GitOKPluginMetadata(
        id: "ThemeGraphitePlugin",
        displayName: GraphiteThemePluginLocalization.string("Graphite Theme"),
        description: GraphiteThemePluginLocalization.string("Neutral graphite dark theme"),
        iconName: "square.grid.3x3",
        order: 134,
        policy: .alwaysOn,
        tableName: GraphiteThemePluginLocalization.table
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



public enum GraphiteThemePluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
