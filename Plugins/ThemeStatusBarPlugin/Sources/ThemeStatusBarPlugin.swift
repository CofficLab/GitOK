import Foundation
import GitOKCoreKit
import SwiftUI

public enum ThemeStatusBarPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "ThemeStatusBarPlugin",
        displayName: ThemeStatusBarPluginLocalization.string("Theme Status"),
        description: ThemeStatusBarPluginLocalization.string("Switch themes from the status bar"),
        iconName: "paintbrush",
        order: 119,
        policy: .optIn,
        tableName: ThemeStatusBarPluginLocalization.table
    )

    public static var introductionContentKind: GitOKPluginAboutContentKind { .statusBar }

    @MainActor
    public static func statusBarTrailingItems(context: GitOKPluginContext) -> [GitOKStatusBarItem] {
        [
            GitOKStatusBarItem(
                id: metadata.id,
                view: AnyView(
                    ThemeStatusBarView(
                        registry: GitOKUIThemeRegistry.shared,
                        selectTheme: context.onThemeSelection
                    )
                )
            ),
        ]
    }
}

public enum ThemeStatusBarPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
