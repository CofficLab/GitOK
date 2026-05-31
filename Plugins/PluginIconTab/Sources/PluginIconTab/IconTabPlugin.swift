import Foundation
import GitOKCoreKit

public struct IconTabPlugin: GitOKPackagedPlugin {
    public static let shared = IconTabPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "IconTabPlugin",
        displayName: PluginIconTabLocalization.string("Icon"),
        description: PluginIconTabLocalization.string("Icon management"),
        iconName: "photo",
        order: 1,
        allowUserToggle: false,
        defaultEnabled: true,
        tableName: PluginIconTabLocalization.table
    )

    private init() {}

    public func tabItem() -> String? {
        Self.metadata.displayName
    }
}

public enum PluginIconTabLocalization {
    public static let table = "IconTab"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
