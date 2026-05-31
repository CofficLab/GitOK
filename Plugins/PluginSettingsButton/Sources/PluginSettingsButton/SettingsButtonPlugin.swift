import Foundation
import GitOKCoreKit
import SwiftUI

public struct SettingsButtonPlugin: GitOKPackagedPlugin {
    public static let shared = SettingsButtonPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "SettingsButton",
        displayName: PluginSettingsButtonLocalization.string("Settings Button"),
        description: PluginSettingsButtonLocalization.string("Show a settings button in the status bar."),
        iconName: "gearshape",
        order: 9000,
        allowUserToggle: true,
        defaultEnabled: true,
        tableName: PluginSettingsButtonLocalization.table
    )

    private init() {}

    public func statusBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        AnyView(SettingsButtonView())
    }
}

public enum PluginSettingsButtonLocalization {
    public static let table = "SettingsButton"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
