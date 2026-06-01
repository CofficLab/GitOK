import Foundation
import GitOKCoreKit
import SwiftUI

public struct OpenVSCodePlugin: GitOKPlugin {
    public static let shared = OpenVSCodePlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "OpenVSCode",
        displayName: PluginOpenVSCodeLocalization.string("Open VS Code"),
        description: PluginOpenVSCodeLocalization.string("Open the current project folder in VS Code."),
        iconName: "chevron.left.forwardslash.chevron.right",
        order: 8400,
        policy: .optOut,
        tableName: PluginOpenVSCodeLocalization.table
    )

    private init() {}

    public func toolBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        guard let projectURL = context.projectURL else { return nil }
        return AnyView(OpenVSCodeButton(projectURL: projectURL))
    }
}

public enum PluginOpenVSCodeLocalization {
    public static let table = "OpenVSCode"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
