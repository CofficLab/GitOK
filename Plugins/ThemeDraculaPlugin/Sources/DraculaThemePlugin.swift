import Foundation
import GitOKCoreKit

public enum DraculaThemePlugin: GitOKPlugin {
    public static let metadata = GitOKPluginMetadata(
        id: "ThemeDraculaPlugin",
        displayName: DraculaThemePluginLocalization.string("Dracula Theme"),
        description: DraculaThemePluginLocalization.string("Classic vivid dark theme"),
        iconName: "moon.stars",
        order: 135,
        policy: .alwaysOn,
        tableName: DraculaThemePluginLocalization.table
    )



    @MainActor
    public static func themeContributions(context: GitOKPluginContext) -> [GitOKUIThemeContribution] {
        [
            GitOKUIThemeContribution(
                sortKey: ThemeSortKey(pluginOrder: Self.metadata.order, themeId: DraculaTheme.dracula.identifier),
                chromeTheme: DraculaTheme.dracula,
                editorThemeId: DraculaTheme.dracula.identifier
            ),
        ]
    }
}



public enum DraculaThemePluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
