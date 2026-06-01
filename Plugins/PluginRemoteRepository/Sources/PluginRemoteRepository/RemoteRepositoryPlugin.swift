import Foundation
import GitOKCoreKit
import SwiftUI

public struct RemoteRepositoryPlugin: GitOKPlugin {
    public static let shared = RemoteRepositoryPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "RemoteRepositoryPlugin",
        displayName: PluginRemoteRepositoryLocalization.string("RemoteRepository"),
        description: PluginRemoteRepositoryLocalization.string("远程仓库管理"),
        iconName: "network",
        policy: .disabled,
        tableName: PluginRemoteRepositoryLocalization.table
    )

    private init() {}

    public func statusBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        guard let projectURL = context.projectURL else { return nil }
        return AnyView(RemoteRepositoryStatusButton(projectURL: projectURL, isGitRepository: context.isGitRepository))
    }
}

public enum PluginRemoteRepositoryLocalization {
    public static let table = "GitRemoteRepository"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
