import Foundation
import GitOKCoreKit
import SwiftUI

public struct GitPullPlugin: GitOKPackagedPlugin {
    public static let shared = GitPullPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "GitPullPlugin",
        displayName: PluginGitPullLocalization.string("GitPull"),
        description: PluginGitPullLocalization.string("Git pull operation"),
        iconName: "arrow.down",
        allowUserToggle: true,
        defaultEnabled: true,
        tableName: PluginGitPullLocalization.table
    )

    private init() {}

    public func toolBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        guard let projectURL = context.projectURL else { return nil }
        return AnyView(GitPullButton(projectURL: projectURL))
    }
}

public enum PluginGitPullLocalization {
    public static let table = "GitPull"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
