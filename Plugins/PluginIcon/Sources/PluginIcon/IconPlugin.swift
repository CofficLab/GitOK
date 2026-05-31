import Foundation
import GitOKCoreKit

public struct IconPlugin: GitOKPlugin {
    public static let shared = IconPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "IconPlugin",
        displayName: PluginIconLocalization.string("plugin-display-name"),
        description: PluginIconLocalization.string("plugin-description"),
        iconName: "photo",
        allowUserToggle: false,
        defaultEnabled: true,
        tableName: PluginIconLocalization.table
    )

    private init() {}
}

public enum PluginIconLocalization {
    public static let table = "Icon"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
