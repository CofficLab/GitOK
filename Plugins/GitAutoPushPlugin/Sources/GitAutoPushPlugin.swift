import Foundation
import GitOKCoreKit
import SwiftUI

public enum GitAutoPushPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "GitAutoPushPlugin",
        displayName: GitAutoPushPluginLocalization.string("Auto Push"),
        description: GitAutoPushPluginLocalization.string("Automatically push the current branch to remote repository."),
        iconName: "arrow.up.circle",
        policy: .optIn,
        tableName: GitAutoPushPluginLocalization.table
    )

    public static var introductionContentKind: GitOKPluginAboutContentKind { .gitTool }

    @MainActor
    public static func statusBarTrailingItems(context: GitOKPluginContext) -> [GitOKStatusBarItem] {
        [
            GitOKStatusBarItem(
                id: metadata.id,
                view: AnyView(
                    AutoPushStatusIcon(
                        projectPath: context.projectPath,
                        projectTitle: context.projectTitle,
                        branchName: context.branchName,
                        isGitRepository: context.isGitRepository
                    )
                )
            ),
        ]
    }
}

public enum GitAutoPushPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
