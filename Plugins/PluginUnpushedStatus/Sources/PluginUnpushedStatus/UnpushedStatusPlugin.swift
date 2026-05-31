import Foundation
import GitOKCoreKit
import SwiftUI

public struct UnpushedStatusPlugin: GitOKPlugin {
    public static let shared = UnpushedStatusPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "UnpushedStatusPlugin",
        displayName: PluginUnpushedStatusLocalization.string("Unpushed Status"),
        description: PluginUnpushedStatusLocalization.string("Display unpushed commit count"),
        iconName: "arrow.up.circle",
        order: 25,
        allowUserToggle: false,
        defaultEnabled: true,
        tableName: PluginUnpushedStatusLocalization.table
    )

    private init() {}

    @MainActor
    public func rootView(_ content: AnyView, context: GitOKPluginContext) -> AnyView? {
        AnyView(UnpushedStatusRootView(
            content: content,
            projectURL: context.projectURL,
            updateUnpushedCommits: context.onUnpushedCommitsUpdate,
            updateRemoteTracking: context.onRemoteTrackingUpdate
        ))
    }
}

public enum PluginUnpushedStatusLocalization {
    public static let table = "UnpushedStatus"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
