import Foundation
import GitOKPluginKit
import SwiftUI

public struct SubmodulePlugin: GitOKPackagedPlugin {
    public static let shared = SubmodulePlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "SubmodulePlugin",
        displayName: PluginSubmoduleLocalization.string("Submodule"),
        description: PluginSubmoduleLocalization.string("Git submodule status and updates"),
        iconName: "shippingbox",
        allowUserToggle: true,
        defaultEnabled: true,
        tableName: PluginSubmoduleLocalization.table
    )

    private init() {}

    @MainActor
    public func statusBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        guard let projectURL = context.projectURL else { return nil }
        return AnyView(SubmoduleStatusTile(projectURL: projectURL))
    }
}

public enum PluginSubmoduleLocalization {
    public static let table = "GitSubmodule"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }

    public static func string(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: string(key), arguments: arguments)
    }
}
