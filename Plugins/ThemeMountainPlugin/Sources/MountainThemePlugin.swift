import GitOKCoreKit

public struct MountainThemePlugin: GitOKPlugin {
    public static let metadata = GitOKPluginMetadata(id: "ThemeMountainPlugin", displayName: "Mountain Theme", description: "Quiet stone light theme", iconName: "archivebox", order: 132, policy: .disabled, tableName: "Localizable")
    public static let shared = MountainThemePlugin()
    private init() {}

    @MainActor
    public func themeContributions() -> [GitOKUIThemeContribution] {
        [GitOKUIThemeContribution(sortKey: ThemeSortKey(pluginOrder: Self.metadata.order, themeId: MountainTheme.mountain.identifier), chromeTheme: MountainTheme.mountain, editorThemeId: MountainTheme.mountain.identifier)]
    }
}
