import Foundation
import GitOKCoreKit
import SwiftUI

public enum GitRemoteRepositoryPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "GitRemoteRepositoryPlugin",
        displayName: GitRemoteRepositoryPluginLocalization.string("RemoteRepository"),
        description: GitRemoteRepositoryPluginLocalization.string("远程仓库管理"),
        iconName: "network",
        policy: .optIn,
        tableName: GitRemoteRepositoryPluginLocalization.table
    )

    public static var introductionContentKind: GitOKPluginAboutContentKind { .gitTool }


    @MainActor
    public static func statusBarTrailingItems(context: GitOKPluginContext) -> [GitOKStatusBarItem] {
        guard let projectURL = context.projectURL else { return [] }
        return [GitOKStatusBarItem(id: metadata.id, view: AnyView(RemoteRepositoryStatusButton(projectURL: projectURL, isGitRepository: context.isGitRepository)))]
    }
}

public enum GitRemoteRepositoryPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
