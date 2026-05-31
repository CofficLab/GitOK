import GitOKCoreKit
import GitOKUI

public struct GlacierThemePlugin: GitOKPlugin {
    public static let metadata = GitOKPluginMetadata(id: "ThemeGlacierPlugin", displayName: "Glacier Theme", description: "Icy cyan light theme", iconName: "externaldrive", order: 129, allowUserToggle: false, defaultEnabled: true, tableName: "ThemeGlacier")
    public static let shared = GlacierThemePlugin()
    private init() {}

    @MainActor
    public func themeContributions() -> [GitOKUIThemeContribution] {
        [GitOKUIThemeContribution(sortKey: ThemeSortKey(pluginOrder: Self.metadata.order, themeId: GlacierTheme.glacier.identifier), chromeTheme: GlacierTheme.glacier, editorThemeId: GlacierTheme.glacier.identifier)]
    }
}
