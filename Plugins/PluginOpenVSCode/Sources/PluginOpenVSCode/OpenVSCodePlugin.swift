import Foundation
import GitOKPluginKit
import SwiftUI

public struct OpenVSCodePlugin: GitOKPackagedPlugin {
    public static let shared = OpenVSCodePlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "OpenVSCode",
        displayName: PluginOpenVSCodeLocalization.string("Open VS Code"),
        description: PluginOpenVSCodeLocalization.string("Open the current project folder in VS Code."),
        iconName: "chevron.left.forwardslash.chevron.right",
        order: 8400,
        allowUserToggle: true,
        defaultEnabled: true,
        tableName: PluginOpenVSCodeLocalization.table
    )

    private init() {}

    public func toolBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        AnyView(OpenVSCodeButton())
    }
}

public enum PluginOpenVSCodeLocalization {
    public static let table = "OpenVSCode"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
