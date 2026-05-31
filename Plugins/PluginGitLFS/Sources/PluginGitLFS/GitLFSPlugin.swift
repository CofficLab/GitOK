import Foundation
import GitOKPluginKit
import SwiftUI

public struct GitLFSPlugin: GitOKPackagedPlugin {
    public static let shared = GitLFSPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "GitLFSPlugin",
        displayName: PluginGitLFSLocalization.string("Git LFS"),
        description: PluginGitLFSLocalization.string("Git LFS status and large file recommendations"),
        iconName: "externaldrive.badge.timemachine",
        order: 9999,
        allowUserToggle: true,
        defaultEnabled: true,
        tableName: PluginGitLFSLocalization.table
    )

    private init() {}

    @MainActor
    public func statusBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        guard let projectURL = context.projectURL else { return nil }
        return AnyView(GitLFSStatusTile(projectURL: projectURL))
    }
}

public enum PluginGitLFSLocalization {
    public static let table = "GitLFS"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
