import Foundation
import GitOKCoreKit
import SwiftUI

public struct SmartMergePlugin: GitOKPlugin {
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
        guard let projectURL = context.projectURL else { return nil }
        return AnyView(SmartMergeStatusTile(projectURL: projectURL, isGitRepository: context.isGitRepository))
    }
}

public enum PluginSmartMergeLocalization {
    public static let table = "GitMerge"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
