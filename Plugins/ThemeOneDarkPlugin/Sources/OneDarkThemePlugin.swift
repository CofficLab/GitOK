import Foundation
import GitOKCoreKit

public enum OneDarkThemePlugin: GitOKPlugin {
    public static let metadata = GitOKPluginMetadata(
        id: "ThemeOneDarkPlugin",
        displayName: OneDarkThemePluginLocalization.string("One Dark Theme"),
        description: OneDarkThemePluginLocalization.string("Classic editor dark theme"),
        iconName: "chevron.left.forwardslash.chevron.right",
        order: 136,
        policy: .alwaysOn,
        tableName: OneDarkThemePluginLocalization.table
    )

    public static var introductionContentKind: GitOKPluginAboutContentKind { .theme }



    @MainActor
    public static func themeContributions(context: GitOKPluginContext) -> [GitOKUIThemeContribution] {
        [
            GitOKUIThemeContribution(
                sortKey: ThemeSortKey(pluginOrder: Self.metadata.order, themeId: OneDarkTheme.oneDark.identifier),
                chromeTheme: OneDarkTheme.oneDark,
                editorThemeId: OneDarkTheme.oneDark.identifier
            ),
        ]
    }
}



public enum OneDarkThemePluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
