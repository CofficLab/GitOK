import Foundation
import GitOKCoreKit
import SwiftUI

public enum SmartMergePlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "SmartMergePlugin",
        displayName: Localization.string("SmartMerge"),
        description: Localization.string("Smart Merge Tool"),
        iconName: "arrow.merge",
        policy: .optIn,
        tableName: Localization.table
    )

    public static var introductionContentKind: GitOKPluginAboutContentKind { .gitTool }


    @MainActor
    public static func statusBarTrailingItems(context: GitOKPluginContext) -> [GitOKStatusBarItem] {
        guard let projectURL = context.projectURL else { return [] }
        return [GitOKStatusBarItem(id: metadata.id, view: AnyView(SmartMergeStatusTile(projectURL: projectURL, isGitRepository: context.isGitRepository)))]
    }
}
