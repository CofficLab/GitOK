import Foundation
import GitOKCoreKit

public struct AuroraThemePlugin: GitOKPlugin {
    public static let metadata = GitOKPluginMetadata(
        id: "ThemeAuroraPlugin",
        displayName: AuroraThemePluginLocalization.string("Aurora Theme"),
        description: AuroraThemePluginLocalization.string("Deep cyan night theme"),
        iconName: "point.3.connected.trianglepath.dotted",
        order: 122,
        policy: .alwaysOn,
        tableName: AuroraThemePluginLocalization.table
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


public enum AuroraThemePluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
