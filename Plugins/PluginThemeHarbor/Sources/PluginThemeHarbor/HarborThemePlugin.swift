import GitOKCoreKit

public struct HarborThemePlugin: GitOKPlugin {
    public static let metadata = GitOKPluginMetadata(id: "ThemeHarborPlugin", displayName: "Harbor Theme", description: "Deep blue water theme", iconName: "network", order: 127, policy: .disabled, tableName: "ThemeHarbor")
    public static let shared = HarborThemePlugin()
    private init() {}

    @MainActor
    public func themeContributions() -> [GitOKUIThemeContribution] {
        [GitOKUIThemeContribution(sortKey: ThemeSortKey(pluginOrder: Self.metadata.order, themeId: HarborTheme.harbor.identifier), chromeTheme: HarborTheme.harbor, editorThemeId: HarborTheme.harbor.identifier)]
    }
}
