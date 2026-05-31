import Foundation
import GitOKPluginKit
import SwiftUI

public struct RemoteRepositoryPlugin: GitOKPackagedPlugin {
    public static let shared = RemoteRepositoryPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "RemoteRepositoryPlugin",
        displayName: PluginRemoteRepositoryLocalization.string("RemoteRepository"),
        description: PluginRemoteRepositoryLocalization.string("远程仓库管理"),
        iconName: "network",
        allowUserToggle: false,
        defaultEnabled: true,
        tableName: PluginRemoteRepositoryLocalization.table
    )

    private init() {}

    public func statusBarTrailingView() -> AnyView? {
        AnyView(RemoteRepositoryStatusButton())
    }
}

public enum PluginRemoteRepositoryLocalization {
    public static let table = "GitRemoteRepository"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
