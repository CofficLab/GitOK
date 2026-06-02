import Foundation
import GitOKCoreKit
import SwiftUI

public struct StashPlugin: GitOKPlugin {
    public static let shared = StashPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "StashPlugin",
        displayName: StashPluginLocalization.string("Stash"),
        description: StashPluginLocalization.string("Git stash management"),
        iconName: "archivebox",
        policy: .optIn,
        tableName: StashPluginLocalization.table
    )

    private init() {}

    @MainActor
    public func statusBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        AnyView(StashStatusTile(projectURL: context.projectURL))
    }
}

public enum StashPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }

    public static func string(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: string(key), arguments: arguments)
    }
}
