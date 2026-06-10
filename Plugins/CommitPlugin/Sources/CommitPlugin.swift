import Foundation
import GitOKCoreKit

public enum CommitPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "CommitPlugin",
        displayName: CommitPluginLocalization.string("Commit"),
        description: CommitPluginLocalization.string("Git commit management"),
        iconName: "arrow.up.arrow.down",
        policy: .alwaysOn,
        tableName: CommitPluginLocalization.table
    )

    @MainActor
    public static func listPaneItems(context: GitOKPluginContext, tab: String) -> [GitOKListPaneItem] {
        guard tab == "Git", context.isGitRepository,
              let view = context.resolve(GitOKAppHostedViewProviding.self)?.commitListView(context: context)
        else { return [] }
        return [GitOKListPaneItem(id: metadata.id, view: view)]
    }
}

public enum CommitPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
