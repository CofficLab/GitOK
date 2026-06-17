import Foundation
import GitOKCoreKit
import SwiftUI

public enum WorkingStatePlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "WorkingStatePlugin",
        displayName: WorkingStatePluginLocalization.string("Working State"),
        description: WorkingStatePluginLocalization.string("Git working tree status and sync"),
        iconName: "tray.2",
        order: 100,
        policy: .alwaysOn,
        tableName: WorkingStatePluginLocalization.table
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
                view: AnyView(WorkingStateView())
            )
        ]
    }
}

public enum WorkingStatePluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
