import Foundation
import GitOKCoreKit

public struct MountainThemePlugin: GitOKPlugin {
    public static let metadata = GitOKPluginMetadata(id: "ThemeMountainPlugin", displayName: MountainThemePluginLocalization.string("Mountain Theme"), description: MountainThemePluginLocalization.string("Quiet stone light theme"), iconName: "archivebox", order: 132, policy: .alwaysOn, tableName: MountainThemePluginLocalization.table)
    public static let shared = MountainThemePlugin()
    private init() {}

    @MainActor
    public func themeContributions() -> [GitOKUIThemeContribution] {
        [GitOKUIThemeContribution(sortKey: ThemeSortKey(pluginOrder: Self.metadata.order, themeId: MountainTheme.mountain.identifier), chromeTheme: MountainTheme.mountain, editorThemeId: MountainTheme.mountain.identifier)]
    }
}


public enum MountainThemePluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
