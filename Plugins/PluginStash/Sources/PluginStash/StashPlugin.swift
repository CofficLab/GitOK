import Foundation
import GitOKCoreKit
import SwiftUI

public struct StashPlugin: GitOKPlugin {
    public static let shared = StashPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "StashPlugin",
        displayName: PluginStashLocalization.string("Stash"),
        description: PluginStashLocalization.string("Git stash management"),
        iconName: "archivebox",
        policy: .alwaysOn,
        tableName: PluginStashLocalization.table
    )

    private init() {}

    @MainActor
    public func statusBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        AnyView(StashStatusTile(projectURL: context.projectURL))
    }
}

public enum PluginStashLocalization {
    public static let table = "GitStash"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }

    public static func string(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: string(key), arguments: arguments)
    }
}
