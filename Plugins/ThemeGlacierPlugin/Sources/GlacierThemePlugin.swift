import Foundation
import GitOKCoreKit

public struct GlacierThemePlugin: GitOKPlugin {
    public static let metadata = GitOKPluginMetadata(id: "ThemeGlacierPlugin", displayName: GlacierThemePluginLocalization.string("Glacier Theme"), description: GlacierThemePluginLocalization.string("Icy cyan light theme"), iconName: "externaldrive", order: 129, policy: .disabled, tableName: GlacierThemePluginLocalization.table)
    public static let shared = GlacierThemePlugin()
    private init() {}

    @MainActor
    public func themeContributions() -> [GitOKUIThemeContribution] {
        [GitOKUIThemeContribution(sortKey: ThemeSortKey(pluginOrder: Self.metadata.order, themeId: GlacierTheme.glacier.identifier), chromeTheme: GlacierTheme.glacier, editorThemeId: GlacierTheme.glacier.identifier)]
    }
}


public enum GlacierThemePluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
