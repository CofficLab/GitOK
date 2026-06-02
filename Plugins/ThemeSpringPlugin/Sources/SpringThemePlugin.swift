import Foundation
import GitOKCoreKit

public struct SpringThemePlugin: GitOKPlugin {
    public static let metadata = GitOKPluginMetadata(
        id: "ThemeSpringPlugin",
        displayName: SpringThemePluginLocalization.string("Spring Theme"),
        description: SpringThemePluginLocalization.string("Fresh green light theme"),
        iconName: "tree",
        order: 121,
        policy: .disabled,
        tableName: SpringThemePluginLocalization.table
    )

    public static let shared = SpringThemePlugin()

    private init() {}

    @MainActor
    public func themeContributions() -> [GitOKUIThemeContribution] {
        [
            GitOKUIThemeContribution(
                sortKey: ThemeSortKey(pluginOrder: Self.metadata.order, themeId: SpringTheme.worktree.identifier),
                chromeTheme: SpringTheme.worktree,
                editorThemeId: SpringTheme.worktree.identifier
            ),
        ]
    }
}


public enum SpringThemePluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
