import Foundation
import GitOKCoreKit

public enum GitWorkspacePlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "GitWorkspacePlugin",
        displayName: GitWorkspacePluginLocalization.string("Commit"),
        description: GitWorkspacePluginLocalization.string("Git commit management"),
        iconName: "arrow.up.arrow.down",
        policy: .alwaysOn,
        tableName: GitWorkspacePluginLocalization.table
    )

    @MainActor
    public static func detailPaneItems(context: GitOKPluginContext, tab: String) -> [GitOKDetailPaneItem] {
        guard tab == "Git",
              let view = context.resolve(GitOKAppHostedViewProviding.self)?.gitDetailView(context: context)
        else { return [] }
        return [GitOKDetailPaneItem(id: "GitDetailPlugin", view: view)]
    }
}

public enum GitWorkspacePluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
