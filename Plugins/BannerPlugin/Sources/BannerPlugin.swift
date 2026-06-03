import Foundation
import GitOKCoreKit

public struct BannerPlugin: GitOKPlugin {
    public static let shared = BannerPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "BannerPlugin",
        displayName: BannerPluginLocalization.string("BannerPlugin"),
        description: "",
        order: 2,
        policy: .alwaysOn,
        tableName: BannerPluginLocalization.table
    )

    private init() {}
}

public enum BannerPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
