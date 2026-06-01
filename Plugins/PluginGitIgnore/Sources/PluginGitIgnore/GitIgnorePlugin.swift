import Foundation
import GitOKCoreKit
import SwiftUI

public struct GitIgnorePlugin: GitOKPlugin {
    public static let shared = GitIgnorePlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "GitignorePlugin",
        displayName: PluginGitIgnoreLocalization.string("Gitignore"),
        description: PluginGitIgnoreLocalization.string("Provides .gitignore viewer in status bar"),
        iconName: "doc.badge.gearshape",
        order: 9999,
        policy: .optOut,
        tableName: PluginGitIgnoreLocalization.table
    )

    private init() {}

    @MainActor
    public func statusBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        guard let projectURL = context.projectURL else { return nil }
        return AnyView(GitIgnoreStatusIcon(projectURL: projectURL))
    }
}

public enum PluginGitIgnoreLocalization {
    public static let table = "GitIgnore"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
