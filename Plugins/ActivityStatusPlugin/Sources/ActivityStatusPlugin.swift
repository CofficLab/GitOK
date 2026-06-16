import Foundation
import GitOKCoreKit
import SwiftUI

public enum ActivityStatusPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "ActivityStatusPlugin",
        displayName: ActivityStatusPluginLocalization.string("Activity Status"),
        description: ActivityStatusPluginLocalization.string("Displays current long-running activity in the status bar."),
        iconName: "arrow.triangle.2.circlepath",
        order: 9999,
        policy: .alwaysOn,
        tableName: ActivityStatusPluginLocalization.table
    )

    public static var introductionContentKind: GitOKPluginAboutContentKind { .statusBar }


    @MainActor
    public static func statusBarCenterItems(context: GitOKPluginContext) -> [GitOKStatusBarItem] {
        return [GitOKStatusBarItem(id: metadata.id, view: AnyView(ActivityStatusTile(activityStatus: context.activityStatus)))]
    }
}

public enum ActivityStatusPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
