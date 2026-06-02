import Foundation
import GitOKCoreKit
import SwiftUI

public struct GitSyncPlugin: GitOKPlugin {
    public static let shared = GitSyncPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "SyncPlugin",
        displayName: GitSyncPluginLocalization.string("Sync"),
        description: GitSyncPluginLocalization.string("Synchronize with remote repository"),
        iconName: "arrow.clockwise",
        order: 9999,
        policy: .disabled,
        tableName: GitSyncPluginLocalization.table
    )

    private init() {}

    public func toolBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        guard let projectURL = context.projectURL else { return nil }
        return AnyView(GitSyncButton(projectURL: projectURL))
    }
}

public enum GitSyncPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
