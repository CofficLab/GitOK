import Foundation
import GitOKCoreKit
import SwiftUI

public enum GitMergePlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "GitMergePlugin",
        displayName: Localization.string("Merge"),
        description: Localization.string("Merge Tool"),
        iconName: "arrow.merge",
        policy: .optIn,
        tableName: Localization.table
    )

    public static var introductionContentKind: GitOKPluginAboutContentKind { .gitTool }


    @MainActor
    public static func statusBarTrailingItems(context: GitOKPluginContext) -> [GitOKStatusBarItem] {
        guard let projectURL = context.projectURL else { return [] }
        return [GitOKStatusBarItem(id: metadata.id, view: AnyView(MergeStatusTile(projectURL: projectURL, isGitRepository: context.isGitRepository)))]
    }
}
