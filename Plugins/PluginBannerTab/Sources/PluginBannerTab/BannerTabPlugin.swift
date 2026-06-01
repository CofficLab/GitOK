import Foundation
import GitOKCoreKit

public struct BannerTabPlugin: GitOKPlugin {
    public static let shared = BannerTabPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "BannerTabPlugin",
        displayName: PluginBannerTabLocalization.string("Banner"),
        description: PluginBannerTabLocalization.string("Banner tab entry"),
        iconName: "rectangle.topthird.inset.filled",
        order: 2,
        policy: .alwaysOn,
        tableName: PluginBannerTabLocalization.table
    )

    private init() {}

    public func tabItem() -> String? {
        Self.metadata.displayName
    }
}

public enum PluginBannerTabLocalization {
    public static let table = "BannerTab"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
