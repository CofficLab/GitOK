import Foundation
import GitOKCoreKit
import SwiftUI

public enum GitStashPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "GitStashPlugin",
        displayName: GitStashPluginLocalization.string("Stash"),
        description: GitStashPluginLocalization.string("Git stash management"),
        iconName: "archivebox",
        policy: .optIn,
        tableName: GitStashPluginLocalization.table
    )

    public static var introductionContentKind: GitOKPluginAboutContentKind { .gitTool }


    @MainActor
    public static func statusBarTrailingItems(context: GitOKPluginContext) -> [GitOKStatusBarItem] {
        return [GitOKStatusBarItem(id: metadata.id, view: AnyView(StashStatusTile(projectURL: context.projectURL)))]
    }
}

public enum GitStashPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }

    public static func string(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: string(key), arguments: arguments)
    }
}
