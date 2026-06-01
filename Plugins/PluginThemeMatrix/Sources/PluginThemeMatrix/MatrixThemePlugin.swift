import GitOKCoreKit

public struct MatrixThemePlugin: GitOKPlugin {
    public static let metadata = GitOKPluginMetadata(
        id: "ThemeMatrixPlugin",
        displayName: "Matrix Theme",
        description: "Electric green dark theme",
        iconName: "gearshape.2",
        order: 131,
        policy: .alwaysOn,
        tableName: "ThemeMatrix"
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
