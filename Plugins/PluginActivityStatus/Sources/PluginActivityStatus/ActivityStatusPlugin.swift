import Foundation
import GitOKCoreKit
import SwiftUI

public struct ActivityStatusPlugin: GitOKPackagedPlugin {
    public static let shared = ActivityStatusPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "ActivityStatusPlugin",
        displayName: PluginActivityStatusLocalization.string("Activity Status"),
        description: PluginActivityStatusLocalization.string("Displays current long-running activity in the status bar."),
        iconName: "arrow.triangle.2.circlepath",
        order: 9999,
        allowUserToggle: false,
        defaultEnabled: true,
        tableName: PluginActivityStatusLocalization.table
    )

    private init() {}

    @MainActor
    public func statusBarCenterView(context: GitOKPluginContext) -> AnyView? {
        AnyView(ActivityStatusTile(activityStatus: context.activityStatus))
    }
}

public enum PluginActivityStatusLocalization {
    public static let table = "ActivityStatus"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
