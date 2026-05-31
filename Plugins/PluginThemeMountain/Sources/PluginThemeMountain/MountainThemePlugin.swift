import GitOKPluginKit
import GitOKUI

public struct MountainThemePlugin: GitOKPackagedPlugin {
    public static let metadata = GitOKPluginMetadata(id: "ThemeMountainPlugin", displayName: "Mountain Theme", description: "Quiet stone light theme", iconName: "archivebox", order: 132, allowUserToggle: false, defaultEnabled: true, tableName: "ThemeMountain")
    public static let shared = MountainThemePlugin()
    private init() {}

    @MainActor
    public func themeContributions() -> [GitOKUIThemeContribution] {
        [GitOKUIThemeContribution(sortKey: ThemeSortKey(pluginOrder: Self.metadata.order, themeId: MountainTheme.mountain.identifier), chromeTheme: MountainTheme.mountain, editorThemeId: MountainTheme.mountain.identifier)]
    }
}
