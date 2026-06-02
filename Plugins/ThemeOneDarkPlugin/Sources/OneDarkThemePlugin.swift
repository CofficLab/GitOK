import Foundation
import GitOKCoreKit

public struct OneDarkThemePlugin: GitOKPlugin {
    public static let metadata = GitOKPluginMetadata(
        id: "ThemeOneDarkPlugin",
        displayName: OneDarkThemePluginLocalization.string("One Dark Theme"),
        description: OneDarkThemePluginLocalization.string("Classic editor dark theme"),
        iconName: "chevron.left.forwardslash.chevron.right",
        order: 136,
        policy: .disabled,
        tableName: OneDarkThemePluginLocalization.table
    )

    public static let shared = OneDarkThemePlugin()

    private init() {}

    @MainActor
    public func themeContributions() -> [GitOKUIThemeContribution] {
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
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
