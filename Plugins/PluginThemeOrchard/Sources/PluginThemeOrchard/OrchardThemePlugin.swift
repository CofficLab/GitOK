import GitOKPluginKit
import GitOKUI

public struct OrchardThemePlugin: GitOKPackagedPlugin {
    public static let metadata = GitOKPluginMetadata(id: "ThemeOrchardPlugin", displayName: "Orchard Theme", description: "Earthy amber dark theme", iconName: "tray.full", order: 128, allowUserToggle: false, defaultEnabled: true, tableName: "ThemeOrchard")
    public static let shared = OrchardThemePlugin()
    private init() {}

    @MainActor
    public func themeContributions() -> [GitOKUIThemeContribution] {
        [GitOKUIThemeContribution(sortKey: ThemeSortKey(pluginOrder: Self.metadata.order, themeId: OrchardTheme.orchard.identifier), chromeTheme: OrchardTheme.orchard, editorThemeId: OrchardTheme.orchard.identifier)]
    }
}
