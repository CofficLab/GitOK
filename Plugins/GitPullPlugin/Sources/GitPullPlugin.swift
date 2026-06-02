import Foundation
import GitOKCoreKit
import SwiftUI

public struct GitPullPlugin: GitOKPlugin {
    public static let shared = GitPullPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "GitPullPlugin",
        displayName: GitPullPluginLocalization.string("GitPull"),
        description: GitPullPluginLocalization.string("Git pull operation"),
        iconName: "arrow.down",
        policy: .disabled,
        tableName: GitPullPluginLocalization.table
    )

    private init() {}

    public func toolBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        guard let projectURL = context.projectURL else { return nil }
        return AnyView(GitPullButton(projectURL: projectURL))
    }
}

public enum GitPullPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
