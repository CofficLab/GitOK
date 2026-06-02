import Foundation
import GitOKCoreKit
import SwiftUI

public struct SettingsButtonPlugin: GitOKPlugin {
    public static let shared = SettingsButtonPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "SettingsButton",
        displayName: SettingsButtonPluginLocalization.string("Settings Button"),
        description: SettingsButtonPluginLocalization.string("Show a settings button in the status bar."),
        iconName: "gearshape",
        order: 9000,
        policy: .optIn,
        tableName: SettingsButtonPluginLocalization.table
    )

    private init() {}

    public func statusBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        AnyView(SettingsButtonView())
    }
}

public enum SettingsButtonPluginLocalization {
    public static let table = "SettingsButton"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
