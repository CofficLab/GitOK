import Foundation
import GitOKCoreKit

public struct OrchardThemePlugin: GitOKPlugin {
    public static let metadata = GitOKPluginMetadata(id: "ThemeOrchardPlugin", displayName: OrchardThemePluginLocalization.string("Orchard Theme"), description: OrchardThemePluginLocalization.string("Earthy amber dark theme"), iconName: "tray.full", order: 128, policy: .disabled, tableName: OrchardThemePluginLocalization.table)
    public static let shared = OrchardThemePlugin()
    private init() {}

    @MainActor
    public func themeContributions() -> [GitOKUIThemeContribution] {
        [GitOKUIThemeContribution(sortKey: ThemeSortKey(pluginOrder: Self.metadata.order, themeId: OrchardTheme.orchard.identifier), chromeTheme: OrchardTheme.orchard, editorThemeId: OrchardTheme.orchard.identifier)]
    }
}


public enum OrchardThemePluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
