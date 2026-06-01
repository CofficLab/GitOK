import Foundation
import GitOKCoreKit
import SwiftUI

public struct ThemeStatusBarPlugin: GitOKPlugin {
    public static let shared = ThemeStatusBarPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "ThemeStatusBarPlugin",
        displayName: PluginThemeStatusBarLocalization.string("Theme Status"),
        description: PluginThemeStatusBarLocalization.string("Switch themes from the status bar"),
        iconName: "paintbrush",
        order: 119,
        policy: .disabled,
        tableName: PluginThemeStatusBarLocalization.table
    )

    private init() {}

    @MainActor
    public func statusBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        AnyView(ThemeStatusBarView(
            registry: GitOKUIThemeRegistry.shared,
            selectTheme: context.onThemeSelection
        ))
    }
}

public enum PluginThemeStatusBarLocalization {
    public static let table = "ThemeStatusBar"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
