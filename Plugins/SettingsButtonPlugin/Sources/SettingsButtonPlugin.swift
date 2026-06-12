import Foundation
import GitOKCoreKit
import SwiftUI

public enum SettingsButtonPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "SettingsButton",
        displayName: SettingsButtonPluginLocalization.string("Settings Button"),
        description: SettingsButtonPluginLocalization.string("Show a settings button in the status bar."),
        iconName: "gearshape",
        order: 9000,
        policy: .optIn,
        tableName: SettingsButtonPluginLocalization.table
    )


    @MainActor
    public static func statusBarTrailingItems(context: GitOKPluginContext) -> [GitOKStatusBarItem] {
        let openSettings: () -> Void = {
            if let navigation = context.resolve(GitOKNavigationServicing.self) {
                navigation.openSettings(tab: nil)
            }
        }
        return [GitOKStatusBarItem(id: metadata.id, view: AnyView(SettingsButtonView(onOpenSettings: openSettings)))]
    }
}

public enum SettingsButtonPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
