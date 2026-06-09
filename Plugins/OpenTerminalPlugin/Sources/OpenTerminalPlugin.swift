import Foundation
import GitOKCoreKit
import SwiftUI

public struct OpenTerminalPlugin: GitOKPlugin {
    public static let shared = OpenTerminalPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "OpenTerminal",
        displayName: OpenTerminalPluginLocalization.string("Open Terminal"),
        description: OpenTerminalPluginLocalization.string("Open the current project folder in Terminal."),
        iconName: "terminal",
        order: 8310,
        policy: .optIn,
        tableName: OpenTerminalPluginLocalization.table
    )

    private init() {}

    public func toolBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        guard let projectURL = context.projectURL else { return nil }
        return AnyView(OpenTerminalButton(projectURL: projectURL))
    }
}

public enum OpenTerminalPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
