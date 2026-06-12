import Foundation
import GitOKCoreKit

public enum EmberThemePlugin: GitOKPlugin {
    public static let metadata = GitOKPluginMetadata(
        id: "ThemeEmberPlugin",
        displayName: EmberThemePluginLocalization.string("Ember Theme"),
        description: EmberThemePluginLocalization.string("Warm orange dark theme"),
        iconName: "exclamationmark.triangle",
        order: 124,
        policy: .alwaysOn,
        tableName: EmberThemePluginLocalization.table
    )



    @MainActor
    public static func themeContributions(context: GitOKPluginContext) -> [GitOKUIThemeContribution] {
        [
            GitOKUIThemeContribution(
                sortKey: ThemeSortKey(pluginOrder: Self.metadata.order, themeId: EmberTheme.conflict.identifier),
                chromeTheme: EmberTheme.conflict,
                editorThemeId: EmberTheme.conflict.identifier
            ),
        ]
    }
}


public enum EmberThemePluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
