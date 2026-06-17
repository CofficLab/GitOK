import Foundation
import GitOKCoreKit
import SwiftUI

public enum GitWorkingStatePlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "GitWorkingStatePlugin",
        displayName: GitWorkingStatePluginLocalization.string("Working State"),
        description: GitWorkingStatePluginLocalization.string("Git working tree status and sync"),
        iconName: "tray.2",
        order: 100,
        policy: .alwaysOn,
        tableName: GitWorkingStatePluginLocalization.table
    )

    @MainActor
    public static func railPaneItems(context: GitOKPluginContext, tab: GitOKAppTab) -> [GitOKRailItem] {
        guard tab == .git, context.isGitRepository else { return [] }
        return [
            GitOKRailItem(
                id: metadata.id,
                iconName: metadata.iconName,
                title: metadata.displayName,
                order: metadata.order,
                view: AnyView(WorkingStateView())
            )
        ]
    }
}

public enum GitWorkingStatePluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
