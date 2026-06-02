import Foundation
import GitOKCoreKit

public struct NebulaThemePlugin: GitOKPlugin {
    public static let metadata = GitOKPluginMetadata(
        id: "ThemeNebulaPlugin",
        displayName: NebulaThemePluginLocalization.string("Nebula Theme"),
        description: NebulaThemePluginLocalization.string("Violet atmospheric dark theme"),
        iconName: "arrow.triangle.pull",
        order: 126,
        policy: .disabled,
        tableName: NebulaThemePluginLocalization.table
    )

    public static let shared = NebulaThemePlugin()

    private init() {}

    @MainActor
    public func themeContributions() -> [GitOKUIThemeContribution] {
        [GitOKUIThemeContribution(sortKey: ThemeSortKey(pluginOrder: Self.metadata.order, themeId: NebulaTheme.nebula.identifier), chromeTheme: NebulaTheme.nebula, editorThemeId: NebulaTheme.nebula.identifier)]
    }
}


public enum NebulaThemePluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
