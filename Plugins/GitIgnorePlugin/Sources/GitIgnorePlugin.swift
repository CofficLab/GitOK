import Foundation
import GitOKCoreKit
import SwiftUI

public enum GitIgnorePlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "GitignorePlugin",
        displayName: GitIgnorePluginLocalization.string("Gitignore"),
        description: GitIgnorePluginLocalization.string("Provides .gitignore viewer in status bar"),
        iconName: "doc.badge.gearshape",
        order: 9999,
        policy: .optIn,
        tableName: GitIgnorePluginLocalization.table
    )


    @MainActor
    public static func statusBarTrailingItems(context: GitOKPluginContext) -> [GitOKStatusBarItem] {
        guard let projectURL = context.projectURL else { return [] }
        return [GitOKStatusBarItem(id: metadata.id, view: AnyView(GitIgnoreStatusIcon(projectURL: projectURL)))]
    }
}

public enum GitIgnorePluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
