import Foundation
import GitOKCoreKit
import SwiftUI

public struct GitWatcherPlugin: GitOKPackagedPlugin {
    public static let shared = GitWatcherPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "GitWatcherPlugin",
        displayName: PluginGitWatcherLocalization.string("Git Watcher"),
        description: PluginGitWatcherLocalization.string("Monitor .git directory changes"),
        iconName: "dot.radiowaves.left.and.right",
        order: 23,
        allowUserToggle: false,
        defaultEnabled: true,
        tableName: PluginGitWatcherLocalization.table
    )

    private init() {}

    @MainActor
    public func rootView(_ content: AnyView, context: GitOKPluginContext) -> AnyView? {
        AnyView(GitWatcherRootView(
            content: content,
            projectURL: context.projectURL,
            gitDirectoryChangeHandler: context.onGitDirectoryChange
        ))
    }
}

public enum PluginGitWatcherLocalization {
    public static let table = "GitWatcher"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
