import Foundation
import GitOKPluginKit
import SwiftUI

public struct CleanStatusPlugin: GitOKPackagedPlugin {
    public static let shared = CleanStatusPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "CleanStatusPlugin",
        displayName: PluginCleanStatusLocalization.string("Clean Status"),
        description: PluginCleanStatusLocalization.string("Track whether project is clean (no uncommitted changes)"),
        iconName: "checkmark.circle",
        order: 24,
        allowUserToggle: false,
        defaultEnabled: true,
        tableName: PluginCleanStatusLocalization.table
    )

    private init() {}

    @MainActor
    public func rootView(_ content: AnyView) -> AnyView? {
        AnyView(CleanStatusRootView(content: content))
    }
}

public enum PluginCleanStatusLocalization {
    public static let table = "CleanStatus"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
