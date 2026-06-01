import GitOKCoreKit

public struct NebulaThemePlugin: GitOKPlugin {
    public static let metadata = GitOKPluginMetadata(
        id: "ThemeNebulaPlugin",
        displayName: "Nebula Theme",
        description: "Violet atmospheric dark theme",
        iconName: "arrow.triangle.pull",
        order: 126,
        policy: .alwaysOn,
        tableName: "ThemeNebula"
    )

    public static let shared = NebulaThemePlugin()

    private init() {}

    @MainActor
    public func themeContributions() -> [GitOKUIThemeContribution] {
        [GitOKUIThemeContribution(sortKey: ThemeSortKey(pluginOrder: Self.metadata.order, themeId: NebulaTheme.nebula.identifier), chromeTheme: NebulaTheme.nebula, editorThemeId: NebulaTheme.nebula.identifier)]
    }
}
