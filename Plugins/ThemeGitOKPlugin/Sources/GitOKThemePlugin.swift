import Foundation
import GitOKCoreKit

public struct GitOKThemePlugin: GitOKPlugin {
    public static let metadata = GitOKPluginMetadata(
        id: "ThemeGitOKPlugin",
        displayName: GitOKThemePluginLocalization.string("GitOK Theme"),
        description: GitOKThemePluginLocalization.string("Default GitOK dark theme"),
        iconName: "folder.badge.gearshape",
        order: 120,
        policy: .alwaysOn,
        tableName: GitOKThemePluginLocalization.table
    )

    public static let shared = GitOKThemePlugin()

    private init() {}

    @MainActor
    public func themeContributions() -> [GitOKUIThemeContribution] {
        [
            GitOKUIThemeContribution(
                sortKey: ThemeSortKey(pluginOrder: Self.metadata.order, themeId: GitOKTheme.repository.identifier),
                chromeTheme: GitOKTheme.repository,
                editorThemeId: GitOKTheme.repository.identifier
            ),
        ]
    }
}


public enum GitOKThemePluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
