import Foundation
import GitOKCoreKit

public struct IconTabPlugin: GitOKPlugin {
    public static let shared = IconTabPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "IconTabPlugin",
        displayName: IconTabPluginLocalization.string("Icon"),
        description: IconTabPluginLocalization.string("Icon management"),
        iconName: "photo",
        order: 1,
        policy: .disabled,
        tableName: IconTabPluginLocalization.table
    )

    private init() {}

    public func tabItem() -> String? {
        Self.metadata.displayName
    }
}

public enum IconTabPluginLocalization {
    public static let table = "IconTab"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
