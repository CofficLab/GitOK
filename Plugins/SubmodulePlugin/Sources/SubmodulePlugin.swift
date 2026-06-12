import Foundation
import GitOKCoreKit
import SwiftUI

public enum SubmodulePlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "SubmodulePlugin",
        displayName: SubmodulePluginLocalization.string("Submodule"),
        description: SubmodulePluginLocalization.string("Git submodule status and updates"),
        iconName: "shippingbox",
        policy: .optIn,
        tableName: SubmodulePluginLocalization.table
    )


    @MainActor
    public static func statusBarTrailingItems(context: GitOKPluginContext) -> [GitOKStatusBarItem] {
        guard let projectURL = context.projectURL else { return [] }
        return [GitOKStatusBarItem(id: metadata.id, view: AnyView(SubmoduleStatusTile(projectURL: projectURL)))]
    }
}

public enum SubmodulePluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }

    public static func string(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: string(key), arguments: arguments)
    }
}
