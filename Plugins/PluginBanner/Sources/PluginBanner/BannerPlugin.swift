import Foundation
import GitOKCoreKit

public struct BannerPlugin: GitOKPlugin {
    public static let shared = BannerPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "BannerPlugin",
        displayName: PluginBannerLocalization.string("BannerPlugin"),
        description: "",
        order: 2,
        policy: .alwaysOn,
        tableName: PluginBannerLocalization.table
    )

    private init() {}
}

public enum PluginBannerLocalization {
    public static let table = "Banner"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
