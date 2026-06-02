import Foundation
import GitOKCoreKit

public struct MatrixThemePlugin: GitOKPlugin {
    public static let metadata = GitOKPluginMetadata(
        id: "ThemeMatrixPlugin",
        displayName: MatrixThemePluginLocalization.string("Matrix Theme"),
        description: MatrixThemePluginLocalization.string("Electric green dark theme"),
        iconName: "gearshape.2",
        order: 131,
        policy: .disabled,
        tableName: MatrixThemePluginLocalization.table
    )

    public static let shared = MatrixThemePlugin()

    private init() {}

    @MainActor
    public func themeContributions() -> [GitOKUIThemeContribution] {
        [
            GitOKUIThemeContribution(
                sortKey: ThemeSortKey(pluginOrder: Self.metadata.order, themeId: MatrixTheme.matrix.identifier),
                chromeTheme: MatrixTheme.matrix,
                editorThemeId: MatrixTheme.matrix.identifier
            ),
        ]
    }
}


public enum MatrixThemePluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
