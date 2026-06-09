import Foundation
import GitOKCoreKit
import SwiftUI

public struct OpenVSCodePlugin: GitOKPlugin {
    public static let shared = OpenVSCodePlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "OpenVSCode",
        displayName: OpenVSCodePluginLocalization.string("Open VS Code"),
        description: OpenVSCodePluginLocalization.string("Open the current project folder in VS Code."),
        iconName: "chevron.left.forwardslash.chevron.right",
        order: 8400,
        policy: .optIn,
        tableName: OpenVSCodePluginLocalization.table
    )

    private init() {}

    public func toolBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        guard let projectURL = context.projectURL else { return nil }
        return AnyView(OpenVSCodeButton(projectURL: projectURL))
    }
}

public enum OpenVSCodePluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
