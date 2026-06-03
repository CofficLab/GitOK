import Foundation
import GitOKCoreKit

public struct MidnightThemePlugin: GitOKPlugin {
    public static let metadata = GitOKPluginMetadata(
        id: "ThemeMidnightPlugin",
        displayName: MidnightThemePluginLocalization.string("Midnight Theme"),
        description: MidnightThemePluginLocalization.string("Quiet terminal-green dark theme"),
        iconName: "terminal",
        order: 123,
        policy: .alwaysOn,
        tableName: MidnightThemePluginLocalization.table
    )

    public static let shared = MidnightThemePlugin()

    private init() {}

    @MainActor
    public func themeContributions() -> [GitOKUIThemeContribution] {
        [
            GitOKUIThemeContribution(
                sortKey: ThemeSortKey(pluginOrder: Self.metadata.order, themeId: MidnightTheme.terminal.identifier),
                chromeTheme: MidnightTheme.terminal,
                editorThemeId: MidnightTheme.terminal.identifier
            ),
        ]
    }
}


public enum MidnightThemePluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
