import Foundation
import GitOKCoreKit
import SwiftUI

public enum IconTabPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "IconTabPlugin",
        displayName: IconTabPluginLocalization.string("Icon"),
        description: IconTabPluginLocalization.string("Icon management"),
        iconName: "photo",
        order: 1,
        policy: .alwaysOn,
        tableName: IconTabPluginLocalization.table
    )


    @MainActor
    public static func tabItems(context: GitOKPluginContext) -> [GitOKTabItem] {
        [GitOKTabItem(id: metadata.id, name: metadata.displayName, order: metadata.order)]
    }
}

public enum IconTabPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
