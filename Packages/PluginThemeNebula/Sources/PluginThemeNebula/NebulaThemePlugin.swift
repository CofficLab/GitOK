import GitOKPluginKit
import GitOKUI

public struct NebulaThemePlugin: GitOKPackagedPlugin {
    public static let metadata = GitOKPluginMetadata(
        id: "ThemeNebulaPlugin",
        displayName: "Nebula Theme",
        description: "Violet atmospheric dark theme",
        iconName: "arrow.triangle.pull",
        order: 126,
        allowUserToggle: false,
        defaultEnabled: true,
        tableName: "ThemeNebula"
    )

    public static let shared = NebulaThemePlugin()

    private init() {}

    @MainActor
    public func themeContributions() -> [GitOKUIThemeContribution] {
        [GitOKUIThemeContribution(sortKey: ThemeSortKey(pluginOrder: Self.metadata.order, themeId: NebulaTheme.nebula.identifier), chromeTheme: NebulaTheme.nebula, editorThemeId: NebulaTheme.nebula.identifier)]
    }
}
