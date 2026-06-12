import Foundation
import GitOKCoreKit

public enum SummerThemePlugin: GitOKPlugin {
    public static let metadata = GitOKPluginMetadata(
        id: "ThemeSummerPlugin",
        displayName: SummerThemePluginLocalization.string("Summer Theme"),
        description: SummerThemePluginLocalization.string("Warm golden light theme"),
        iconName: "tag",
        order: 130,
        policy: .alwaysOn,
        tableName: SummerThemePluginLocalization.table
    )



    @MainActor
    public static func themeContributions(context: GitOKPluginContext) -> [GitOKUIThemeContribution] {
        [
            GitOKUIThemeContribution(
                sortKey: ThemeSortKey(pluginOrder: Self.metadata.order, themeId: SummerTheme.release.identifier),
                chromeTheme: SummerTheme.release,
                editorThemeId: SummerTheme.release.identifier
            ),
        ]
    }
}



public enum SummerThemePluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
