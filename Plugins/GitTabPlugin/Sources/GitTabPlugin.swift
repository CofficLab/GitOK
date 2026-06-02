import Foundation
import GitOKCoreKit

public struct GitTabPlugin: GitOKPlugin {
    public static let shared = GitTabPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "GitTabPlugin",
        displayName: GitTabPluginLocalization.string("Git"),
        description: GitTabPluginLocalization.string("Git version control"),
        iconName: "arrow.up.arrow.down",
        order: 0,
        policy: .disabled,
        tableName: GitTabPluginLocalization.table
    )

    private init() {}

    public func tabItem() -> String? {
        Self.metadata.displayName
    }
}

public enum GitTabPluginLocalization {
    public static let table = "GitTab"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
