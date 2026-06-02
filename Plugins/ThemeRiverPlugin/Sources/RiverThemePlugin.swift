import Foundation
import GitOKCoreKit

public struct RiverThemePlugin: GitOKPlugin {
    public static let metadata = GitOKPluginMetadata(
        id: "ThemeRiverPlugin",
        displayName: RiverThemePluginLocalization.string("River Theme"),
        description: RiverThemePluginLocalization.string("Flowing teal dark theme"),
        iconName: "arrow.triangle.branch",
        order: 125,
        policy: .alwaysOn,
        tableName: RiverThemePluginLocalization.table
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


public enum RiverThemePluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
