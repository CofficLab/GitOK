import Foundation
import GitOKCoreKit

public struct XcodeLightThemePlugin: GitOKPlugin {
    public static let metadata = GitOKPluginMetadata(
        id: "ThemeXcodeLightPlugin",
        displayName: XcodeLightThemePluginLocalization.string("Xcode Light Theme"),
        description: XcodeLightThemePluginLocalization.string("Xcode-inspired light theme"),
        iconName: "hammer",
        order: 137,
        policy: .alwaysOn,
        tableName: XcodeLightThemePluginLocalization.table
    )

    public static let shared = XcodeLightThemePlugin()

    private init() {}

    @MainActor
    public func themeContributions() -> [GitOKUIThemeContribution] {
        [
            GitOKUIThemeContribution(
                sortKey: ThemeSortKey(pluginOrder: Self.metadata.order, themeId: XcodeLightTheme.xcodeLight.identifier),
                chromeTheme: XcodeLightTheme.xcodeLight,
                editorThemeId: XcodeLightTheme.xcodeLight.identifier
            ),
        ]
    }
}



public enum XcodeLightThemePluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
