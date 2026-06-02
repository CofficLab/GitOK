import GitOKCoreKit

public struct OrchardThemePlugin: GitOKPlugin {
    public static let metadata = GitOKPluginMetadata(id: "ThemeOrchardPlugin", displayName: "Orchard Theme", description: "Earthy amber dark theme", iconName: "tray.full", order: 128, policy: .disabled, tableName: "ThemeOrchard")
    public static let shared = OrchardThemePlugin()
    private init() {}

    @MainActor
    public func themeContributions() -> [GitOKUIThemeContribution] {
        [GitOKUIThemeContribution(sortKey: ThemeSortKey(pluginOrder: Self.metadata.order, themeId: OrchardTheme.orchard.identifier), chromeTheme: OrchardTheme.orchard, editorThemeId: OrchardTheme.orchard.identifier)]
    }
}
