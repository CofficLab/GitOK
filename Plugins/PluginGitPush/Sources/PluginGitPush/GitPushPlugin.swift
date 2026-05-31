import Foundation
import GitOKPluginKit
import SwiftUI

public struct GitPushPlugin: GitOKPackagedPlugin {
    public static let shared = GitPushPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "GitPushPlugin",
        displayName: PluginGitPushLocalization.string("Git Sync"),
        description: PluginGitPushLocalization.string("根据分支状态执行 Fetch、Pull 或 Push"),
        iconName: "arrow.triangle.2.circlepath",
        allowUserToggle: true,
        defaultEnabled: true,
        tableName: PluginGitPushLocalization.table
    )

    private init() {}

    public func toolBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        AnyView(GitPushButton())
    }
}

public enum PluginGitPushLocalization {
    public static let table = "GitPush"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
