import Foundation
import GitOKPluginKit
import SwiftUI

public struct OpenTerminalPlugin: GitOKPackagedPlugin {
    public static let shared = OpenTerminalPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "OpenTerminal",
        displayName: PluginOpenTerminalLocalization.string("Open Terminal"),
        description: PluginOpenTerminalLocalization.string("Open the current project folder in Terminal."),
        iconName: "terminal",
        order: 8310,
        allowUserToggle: true,
        defaultEnabled: true,
        tableName: PluginOpenTerminalLocalization.table
    )

    private init() {}

    public func toolBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        AnyView(OpenTerminalButton())
    }
}

public enum PluginOpenTerminalLocalization {
    public static let table = "OpenTerminal"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
