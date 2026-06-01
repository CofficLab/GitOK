import Foundation
import GitOKCoreKit
import SwiftUI

public struct OpenTerminalPlugin: GitOKPlugin {
    public static let shared = OpenTerminalPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "OpenTerminal",
        displayName: PluginOpenTerminalLocalization.string("Open Terminal"),
        description: PluginOpenTerminalLocalization.string("Open the current project folder in Terminal."),
        iconName: "terminal",
        order: 8310,
        policy: .disabled,
        tableName: PluginOpenTerminalLocalization.table
    )

    private init() {}

    public func toolBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        guard let projectURL = context.projectURL else { return nil }
        return AnyView(OpenTerminalButton(projectURL: projectURL))
    }
}

public enum PluginOpenTerminalLocalization {
    public static let table = "OpenTerminal"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
