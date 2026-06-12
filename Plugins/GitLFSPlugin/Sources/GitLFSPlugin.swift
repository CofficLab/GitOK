import Foundation
import GitOKCoreKit
import SwiftUI

public enum GitLFSPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "GitLFSPlugin",
        displayName: GitLFSPluginLocalization.string("Git LFS"),
        description: GitLFSPluginLocalization.string("Git LFS status and large file recommendations"),
        iconName: "externaldrive.badge.timemachine",
        order: 9999,
        policy: .optIn,
        tableName: GitLFSPluginLocalization.table
    )


    @MainActor
    public static func statusBarTrailingItems(context: GitOKPluginContext) -> [GitOKStatusBarItem] {
        guard let projectURL = context.projectURL else { return [] }
        return [GitOKStatusBarItem(id: metadata.id, view: AnyView(GitLFSStatusTile(projectURL: projectURL)))]
    }
}

public enum GitLFSPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
