import Foundation
import GitOKCoreKit
import SwiftUI

public enum GitTabPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "GitTabPlugin",
        displayName: GitTabPluginLocalization.string("Git"),
        description: GitTabPluginLocalization.string("Git version control"),
        iconName: "arrow.up.arrow.down",
        order: 0,
        policy: .alwaysOn,
        tableName: GitTabPluginLocalization.table
    )


    @MainActor
    public static func tabItems(context: GitOKPluginContext) -> [GitOKTabItem] {
        [GitOKTabItem(id: metadata.id, name: metadata.displayName, order: metadata.order)]
    }
}

public enum GitTabPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
