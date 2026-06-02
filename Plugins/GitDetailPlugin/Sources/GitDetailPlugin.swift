import Foundation
import GitOKCoreKit

public struct GitDetailPlugin: GitOKPlugin {
    public static let shared = GitDetailPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "GitDetailPlugin",
        displayName: GitDetailPluginLocalization.string("GitDetailPlugin"),
        description: "",
        order: 0,
        policy: .disabled,
        tableName: GitDetailPluginLocalization.table
    )

    private init() {}
}

public enum GitDetailPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
