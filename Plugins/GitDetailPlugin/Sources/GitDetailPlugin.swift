import Foundation
import GitOKCoreKit

public enum GitDetailPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "GitDetailPlugin",
        displayName: GitDetailPluginLocalization.string("GitDetailPlugin"),
        description: "",
        order: 0,
        policy: .alwaysOn,
        tableName: GitDetailPluginLocalization.table
    )

    @MainActor
    public static func detailPaneItems(context: GitOKPluginContext, tab: String) -> [GitOKDetailPaneItem] {
        guard tab == "Git",
              let view = context.resolve(GitOKAppHostedViewProviding.self)?.gitDetailView(context: context)
        else { return [] }
        return [GitOKDetailPaneItem(id: metadata.id, view: view)]
    }
}

public enum GitDetailPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
