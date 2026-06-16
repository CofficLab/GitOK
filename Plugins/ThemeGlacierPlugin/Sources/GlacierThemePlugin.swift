import Foundation
import GitOKCoreKit

public enum GlacierThemePlugin: GitOKPlugin {
    public static let metadata = GitOKPluginMetadata(id: "ThemeGlacierPlugin", displayName: GlacierThemePluginLocalization.string("Glacier Theme"), description: GlacierThemePluginLocalization.string("Icy cyan light theme"), iconName: "externaldrive", order: 129, policy: .alwaysOn, tableName: GlacierThemePluginLocalization.table)

    public static var introductionContentKind: GitOKPluginAboutContentKind { .theme }

    @MainActor
    public static func themeContributions(context: GitOKPluginContext) -> [GitOKUIThemeContribution] {
        [GitOKUIThemeContribution(sortKey: ThemeSortKey(pluginOrder: Self.metadata.order, themeId: GlacierTheme.glacier.identifier), chromeTheme: GlacierTheme.glacier, editorThemeId: GlacierTheme.glacier.identifier)]
    }
}


public enum GlacierThemePluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
