import Foundation
import GitOKCoreKit
import SwiftUI

public enum GitConflictResolverPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "GitConflictResolverPlugin",
        displayName: GitConflictResolverPluginLocalization.string("ConflictResolver"),
        description: GitConflictResolverPluginLocalization.string("Git 冲突解决"),
        iconName: "exclamationmark.triangle",
        policy: .optIn,
        tableName: GitConflictResolverPluginLocalization.table
    )

    public static var introductionContentKind: GitOKPluginAboutContentKind { .gitTool }


    @MainActor
    public static func statusBarTrailingItems(context: GitOKPluginContext) -> [GitOKStatusBarItem] {
        guard let projectURL = context.projectURL else { return [] }
        return [GitOKStatusBarItem(id: metadata.id, view: AnyView(ConflictStatusTile(projectURL: projectURL, isGitRepository: context.isGitRepository)))]
    }

    @MainActor
    public static func rootOverlay(context: GitOKPluginContext, content: AnyView) -> AnyView? {
        return         AnyView(ConflictResolverRootView(
            content: content,
            projectURL: context.projectURL,
            isGitRepository: context.isGitRepository
        ))
    }
}

public enum GitConflictResolverPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
