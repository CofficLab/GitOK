import Foundation
import GitOKCoreKit
import SwiftUI

public struct OpenKiroPlugin: GitOKPlugin {
    public static let shared = OpenKiroPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "OpenKiro",
        displayName: PluginOpenKiroLocalization.string("Open Kiro"),
        description: PluginOpenKiroLocalization.string("Open the current project folder in Kiro."),
        iconName: "water.waves",
        order: 8405,
        policy: .disabled,
        tableName: PluginOpenKiroLocalization.table
    )

    private init() {}

    public func toolBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        guard let projectURL = context.projectURL else { return nil }
        return AnyView(OpenKiroButton(projectURL: projectURL))
    }
}

public enum PluginOpenKiroLocalization {
    public static let table = "OpenKiro"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
