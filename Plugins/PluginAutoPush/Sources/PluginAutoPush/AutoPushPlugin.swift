import Foundation
import GitOKPluginKit
import SwiftUI

public struct AutoPushPlugin: GitOKPackagedPlugin {
    public static let shared = AutoPushPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "AutoPushPlugin",
        displayName: PluginAutoPushLocalization.string("Auto Push"),
        description: PluginAutoPushLocalization.string("Automatically push the current branch to remote repository."),
        iconName: "arrow.up.circle",
        allowUserToggle: true,
        defaultEnabled: false,
        tableName: PluginAutoPushLocalization.table
    )

    private init() {}

    @MainActor
    public func statusBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        AnyView(AutoPushStatusIcon())
    }
}

public enum PluginAutoPushLocalization {
    public static let table = "AutoPush"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
