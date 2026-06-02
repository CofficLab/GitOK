import Foundation
import GitOKCoreKit
import SwiftUI

public struct ActivityStatusPlugin: GitOKPlugin {
    public static let shared = ActivityStatusPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "ActivityStatusPlugin",
        displayName: ActivityStatusPluginLocalization.string("Activity Status"),
        description: ActivityStatusPluginLocalization.string("Displays current long-running activity in the status bar."),
        iconName: "arrow.triangle.2.circlepath",
        order: 9999,
        policy: .optIn,
        tableName: ActivityStatusPluginLocalization.table
    )

    private init() {}

    @MainActor
    public func statusBarCenterView(context: GitOKPluginContext) -> AnyView? {
        AnyView(ActivityStatusTile(activityStatus: context.activityStatus))
    }
}

public enum ActivityStatusPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
