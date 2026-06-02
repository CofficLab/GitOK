import Foundation
import GitOKCoreKit
import SwiftUI

public struct GitIgnorePlugin: GitOKPlugin {
    public static let shared = GitIgnorePlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "GitignorePlugin",
        displayName: GitIgnorePluginLocalization.string("Gitignore"),
        description: GitIgnorePluginLocalization.string("Provides .gitignore viewer in status bar"),
        iconName: "doc.badge.gearshape",
        order: 9999,
        policy: .optIn,
        tableName: GitIgnorePluginLocalization.table
    )

    private init() {}

    @MainActor
    public func statusBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        guard let projectURL = context.projectURL else { return nil }
        return AnyView(GitIgnoreStatusIcon(projectURL: projectURL))
    }
}

public enum GitIgnorePluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
