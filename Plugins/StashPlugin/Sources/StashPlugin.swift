import Foundation
import GitOKCoreKit
import SwiftUI

public enum StashPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "StashPlugin",
        displayName: StashPluginLocalization.string("Stash"),
        description: StashPluginLocalization.string("Git stash management"),
        iconName: "archivebox",
        policy: .optIn,
        tableName: StashPluginLocalization.table
    )

    public static var introductionContentKind: GitOKPluginAboutContentKind { .gitTool }


    @MainActor
    public static func statusBarTrailingItems(context: GitOKPluginContext) -> [GitOKStatusBarItem] {
        return [GitOKStatusBarItem(id: metadata.id, view: AnyView(StashStatusTile(projectURL: context.projectURL)))]
    }
}

public enum StashPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }

    public static func string(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: string(key), arguments: arguments)
    }
}
