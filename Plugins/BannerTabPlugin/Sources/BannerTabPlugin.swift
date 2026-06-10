import Foundation
import GitOKCoreKit
import SwiftUI

public enum BannerTabPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "BannerTabPlugin",
        displayName: BannerTabPluginLocalization.string("Banner"),
        description: BannerTabPluginLocalization.string("Banner tab entry"),
        iconName: "rectangle.topthird.inset.filled",
        order: 2,
        policy: .alwaysOn,
        tableName: BannerTabPluginLocalization.table
    )


    @MainActor
    public static func tabItems(context: GitOKPluginContext) -> [GitOKTabItem] {
        [GitOKTabItem(id: metadata.id, name: metadata.displayName, order: metadata.order)]
    }
}

public enum BannerTabPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
