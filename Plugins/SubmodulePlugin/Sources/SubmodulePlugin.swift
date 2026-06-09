import Foundation
import GitOKCoreKit
import SwiftUI

public struct SubmodulePlugin: GitOKPlugin {
    public static let shared = SubmodulePlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "SubmodulePlugin",
        displayName: SubmodulePluginLocalization.string("Submodule"),
        description: SubmodulePluginLocalization.string("Git submodule status and updates"),
        iconName: "shippingbox",
        policy: .optIn,
        tableName: SubmodulePluginLocalization.table
    )

    private init() {}

    @MainActor
    public func statusBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        guard let projectURL = context.projectURL else { return nil }
        return AnyView(SubmoduleStatusTile(projectURL: projectURL))
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
