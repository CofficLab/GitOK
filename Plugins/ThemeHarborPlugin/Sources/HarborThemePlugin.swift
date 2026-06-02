import Foundation
import GitOKCoreKit

public struct HarborThemePlugin: GitOKPlugin {
    public static let metadata = GitOKPluginMetadata(id: "ThemeHarborPlugin", displayName: HarborThemePluginLocalization.string("Harbor Theme"), description: HarborThemePluginLocalization.string("Deep blue water theme"), iconName: "network", order: 127, policy: .disabled, tableName: HarborThemePluginLocalization.table)
    public static let shared = HarborThemePlugin()
    private init() {}

    @MainActor
    public func themeContributions() -> [GitOKUIThemeContribution] {
        [GitOKUIThemeContribution(sortKey: ThemeSortKey(pluginOrder: Self.metadata.order, themeId: HarborTheme.harbor.identifier), chromeTheme: HarborTheme.harbor, editorThemeId: HarborTheme.harbor.identifier)]
    }
}


public enum HarborThemePluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
