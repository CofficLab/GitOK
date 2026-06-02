import Foundation
import GitOKCoreKit

public struct BannerTabPlugin: GitOKPlugin {
    public static let shared = BannerTabPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "BannerTabPlugin",
        displayName: BannerTabPluginLocalization.string("Banner"),
        description: BannerTabPluginLocalization.string("Banner tab entry"),
        iconName: "rectangle.topthird.inset.filled",
        order: 2,
        policy: .alwaysOn,
        tableName: BannerTabPluginLocalization.table
    )

    private init() {}

    public func tabItem() -> String? {
        Self.metadata.displayName
    }
}

public enum BannerTabPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
