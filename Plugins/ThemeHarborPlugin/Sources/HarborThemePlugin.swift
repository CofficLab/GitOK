import Foundation
import GitOKCoreKit

public enum HarborThemePlugin: GitOKPlugin {
    public static let metadata = GitOKPluginMetadata(id: "ThemeHarborPlugin", displayName: HarborThemePluginLocalization.string("Harbor Theme"), description: HarborThemePluginLocalization.string("Deep blue water theme"), iconName: "network", order: 127, policy: .alwaysOn, tableName: HarborThemePluginLocalization.table)

    public static var introductionContentKind: GitOKPluginAboutContentKind { .theme }

    @MainActor
    public static func themeContributions(context: GitOKPluginContext) -> [GitOKUIThemeContribution] {
        [GitOKUIThemeContribution(sortKey: ThemeSortKey(pluginOrder: Self.metadata.order, themeId: HarborTheme.harbor.identifier), chromeTheme: HarborTheme.harbor, editorThemeId: HarborTheme.harbor.identifier)]
    }
}


public enum HarborThemePluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
