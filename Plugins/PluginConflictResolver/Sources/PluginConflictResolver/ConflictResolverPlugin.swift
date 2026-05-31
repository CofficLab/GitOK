import Foundation
import GitOKPluginKit
import SwiftUI

public struct ConflictResolverPlugin: GitOKPackagedPlugin {
    public static let shared = ConflictResolverPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "ConflictResolverPlugin",
        displayName: PluginConflictResolverLocalization.string("ConflictResolver"),
        description: PluginConflictResolverLocalization.string("Git 冲突解决"),
        iconName: "exclamationmark.triangle",
        allowUserToggle: false,
        defaultEnabled: true,
        tableName: PluginConflictResolverLocalization.table
    )

    private init() {}

    public func statusBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        AnyView(ConflictStatusTile())
    }
}

public enum PluginConflictResolverLocalization {
    public static let table = "GitConflictResolver"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
