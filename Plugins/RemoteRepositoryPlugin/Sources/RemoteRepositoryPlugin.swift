import Foundation
import GitOKCoreKit
import SwiftUI

public enum RemoteRepositoryPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "RemoteRepositoryPlugin",
        displayName: RemoteRepositoryPluginLocalization.string("RemoteRepository"),
        description: RemoteRepositoryPluginLocalization.string("远程仓库管理"),
        iconName: "network",
        policy: .optIn,
        tableName: RemoteRepositoryPluginLocalization.table
    )

    public static var introductionContentKind: GitOKPluginAboutContentKind { .gitTool }


    @MainActor
    public static func statusBarTrailingItems(context: GitOKPluginContext) -> [GitOKStatusBarItem] {
        guard let projectURL = context.projectURL else { return [] }
        return [GitOKStatusBarItem(id: metadata.id, view: AnyView(RemoteRepositoryStatusButton(projectURL: projectURL, isGitRepository: context.isGitRepository)))]
    }
}

public enum RemoteRepositoryPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
