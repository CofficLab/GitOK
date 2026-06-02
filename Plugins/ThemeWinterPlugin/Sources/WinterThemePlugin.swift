import Foundation
import GitOKCoreKit

public struct WinterThemePlugin: GitOKPlugin {
    public static let metadata = GitOKPluginMetadata(
        id: "ThemeWinterPlugin",
        displayName: WinterThemePluginLocalization.string("Winter Theme"),
        description: WinterThemePluginLocalization.string("Cool minimal light theme"),
        iconName: "scope",
        order: 133,
        policy: .disabled,
        tableName: WinterThemePluginLocalization.table
    )

    public static let shared = WinterThemePlugin()

    private init() {}

    @MainActor
    public func themeContributions() -> [GitOKUIThemeContribution] {
        [
            GitOKUIThemeContribution(
                sortKey: ThemeSortKey(pluginOrder: Self.metadata.order, themeId: WinterTheme.focus.identifier),
                chromeTheme: WinterTheme.focus,
                editorThemeId: WinterTheme.focus.identifier
            ),
        ]
    }
}



public enum WinterThemePluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
