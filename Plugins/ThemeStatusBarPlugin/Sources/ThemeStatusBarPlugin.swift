import Foundation
import GitOKCoreKit
import SwiftUI

public struct ThemeStatusBarPlugin: GitOKPlugin {
    public static let shared = ThemeStatusBarPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "ThemeStatusBarPlugin",
        displayName: ThemeStatusBarPluginLocalization.string("Theme Status"),
        description: ThemeStatusBarPluginLocalization.string("Switch themes from the status bar"),
        iconName: "paintbrush",
        order: 119,
        policy: .optIn,
        tableName: ThemeStatusBarPluginLocalization.table
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

public enum ThemeStatusBarPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
