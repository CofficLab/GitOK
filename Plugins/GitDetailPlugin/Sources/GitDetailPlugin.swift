import Foundation
import GitOKCoreKit
import SwiftUI

public enum GitDetailPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "GitDetailPlugin",
        displayName: GitDetailPluginLocalization.string("Git Detail"),
        description: GitDetailPluginLocalization.string("Git working tree changes and diff detail"),
        iconName: "doc.text.magnifyingglass",
        order: 120,
        policy: .alwaysOn,
        tableName: GitDetailPluginLocalization.table
    )

    @MainActor
    public static func detailPaneItems(context: GitOKPluginContext, tab: GitOKAppTab) -> [DetailPane] {
        guard tab == .git, context.isGitRepository else { return [] }
        return [
            DetailPane(
                id: metadata.id,
                view: AnyView(GitDetailView())
            )
        ]
    }
}

public enum GitDetailPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
