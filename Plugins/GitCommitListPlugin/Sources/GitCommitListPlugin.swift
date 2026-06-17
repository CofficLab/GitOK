import Foundation
import GitOKCoreKit
import SwiftUI

public enum GitCommitListPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "GitCommitListPlugin",
        displayName: GitCommitListPluginLocalization.string("Commit"),
        description: GitCommitListPluginLocalization.string("Git commit management"),
        iconName: "arrow.up.arrow.down",
        order: 110,
        policy: .alwaysOn,
        tableName: GitCommitListPluginLocalization.table
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

public enum GitCommitListPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
