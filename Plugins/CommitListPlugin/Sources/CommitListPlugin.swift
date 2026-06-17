import Foundation
import GitOKCoreKit
import SwiftUI

public enum CommitListPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "CommitListPlugin",
        displayName: CommitListPluginLocalization.string("Commit"),
        description: CommitListPluginLocalization.string("Git commit management"),
        iconName: "arrow.up.arrow.down",
        order: 110,
        policy: .alwaysOn,
        tableName: CommitListPluginLocalization.table
    )

    @MainActor
    public static func railPaneItems(context: GitOKPluginContext, tab: String) -> [GitOKRailItem] {
        guard tab == "Git", context.isGitRepository else { return [] }
        return [
            GitOKRailItem(
                id: metadata.id,
                iconName: metadata.iconName,
                title: metadata.displayName,
                order: metadata.order,
                view: AnyView(CommitListView())
            )
        ]
    }
}

public enum CommitListPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
