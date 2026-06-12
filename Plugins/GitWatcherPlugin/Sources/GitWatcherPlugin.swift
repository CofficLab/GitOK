import Foundation
import GitOKCoreKit
import SwiftUI

public enum GitWatcherPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "GitWatcherPlugin",
        displayName: GitWatcherPluginLocalization.string("Git Watcher"),
        description: GitWatcherPluginLocalization.string("Monitor .git directory changes"),
        iconName: "dot.radiowaves.left.and.right",
        order: 23,
        policy: .alwaysOn,
        tableName: GitWatcherPluginLocalization.table
    )


    @MainActor
    public static func rootOverlay(context: GitOKPluginContext, content: AnyView) -> AnyView? {
        return         AnyView(GitWatcherRootView(
            content: content,
            projectURL: context.projectURL,
            gitDirectoryChangeHandler: context.onGitDirectoryChange
        ))
    }
}

public enum GitWatcherPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
