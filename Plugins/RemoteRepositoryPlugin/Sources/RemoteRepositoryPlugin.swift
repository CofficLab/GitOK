import Foundation
import GitOKCoreKit
import SwiftUI

public struct RemoteRepositoryPlugin: GitOKPlugin {
    public static let shared = RemoteRepositoryPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "RemoteRepositoryPlugin",
        displayName: RemoteRepositoryPluginLocalization.string("RemoteRepository"),
        description: RemoteRepositoryPluginLocalization.string("远程仓库管理"),
        iconName: "network",
        policy: .optIn,
        tableName: RemoteRepositoryPluginLocalization.table
    )

    private init() {}

    public func statusBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        guard let projectURL = context.projectURL else { return nil }
        return AnyView(RemoteRepositoryStatusButton(projectURL: projectURL, isGitRepository: context.isGitRepository))
    }
}

public enum RemoteRepositoryPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
