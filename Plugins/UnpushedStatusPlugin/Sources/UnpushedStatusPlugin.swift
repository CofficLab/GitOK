import Foundation
import GitOKCoreKit
import SwiftUI

public struct UnpushedStatusPlugin: GitOKPlugin {
    public static let shared = UnpushedStatusPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "UnpushedStatusPlugin",
        displayName: UnpushedStatusPluginLocalization.string("Unpushed Status"),
        description: UnpushedStatusPluginLocalization.string("Display unpushed commit count"),
        iconName: "arrow.up.circle",
        order: 25,
        policy: .disabled,
        tableName: UnpushedStatusPluginLocalization.table
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

public enum UnpushedStatusPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
