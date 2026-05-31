import Foundation
import GitOKPluginKit
import SwiftUI

public struct SmartMergePlugin: GitOKPackagedPlugin {
    public static let shared = SmartMergePlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "SmartMergePlugin",
        displayName: PluginSmartMergeLocalization.string("SmartMerge"),
        description: PluginSmartMergeLocalization.string("智能合并工具"),
        iconName: "arrow.merge",
        allowUserToggle: true,
        defaultEnabled: true,
        tableName: PluginSmartMergeLocalization.table
    )

    private init() {}

    public func statusBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        AnyView(SmartMergeStatusTile())
    }
}

public enum PluginSmartMergeLocalization {
    public static let table = "GitMerge"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
