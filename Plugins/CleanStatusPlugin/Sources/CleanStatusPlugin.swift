import Foundation
import GitOKCoreKit
import SwiftUI

public struct CleanStatusPlugin: GitOKPlugin {
    public static let shared = CleanStatusPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "CleanStatusPlugin",
        displayName: CleanStatusPluginLocalization.string("Clean Status"),
        description: CleanStatusPluginLocalization.string("Track whether project is clean (no uncommitted changes)"),
        iconName: "checkmark.circle",
        order: 24,
        policy: .disabled,
        tableName: CleanStatusPluginLocalization.table
    )

    private init() {}

    @MainActor
    public func rootView(_ content: AnyView, context: GitOKPluginContext) -> AnyView? {
        AnyView(CleanStatusRootView(
            content: content,
            projectURL: context.projectURL,
            updateCleanStatus: context.onCleanStatusUpdate
        ))
    }
}

public enum CleanStatusPluginLocalization {
    public static let table = "CleanStatus"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
