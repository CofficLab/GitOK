import Foundation
import GitOKCoreKit
import SwiftUI

public struct GitSyncPlugin: GitOKPlugin {
    public static let shared = GitSyncPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "SyncPlugin",
        displayName: PluginGitSyncLocalization.string("Sync"),
        description: PluginGitSyncLocalization.string("Synchronize with remote repository"),
        iconName: "arrow.clockwise",
        order: 9999,
        policy: .disabled,
        tableName: PluginGitSyncLocalization.table
    )

    private init() {}

    public func toolBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        guard let projectURL = context.projectURL else { return nil }
        return AnyView(GitSyncButton(projectURL: projectURL))
    }
}

public enum PluginGitSyncLocalization {
    public static let table = "GitSync"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
