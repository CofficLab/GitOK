import Foundation
import GitOKCoreKit

public enum SpringThemePlugin: GitOKPlugin {
    public static let metadata = GitOKPluginMetadata(
        id: "ThemeSpringPlugin",
        displayName: SpringThemePluginLocalization.string("Spring Theme"),
        description: SpringThemePluginLocalization.string("Fresh green light theme"),
        iconName: "tree",
        order: 121,
        policy: .alwaysOn,
        tableName: SpringThemePluginLocalization.table
    )

    public static var introductionContentKind: GitOKPluginAboutContentKind { .theme }



    @MainActor
    public static func themeContributions(context: GitOKPluginContext) -> [GitOKUIThemeContribution] {
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
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
