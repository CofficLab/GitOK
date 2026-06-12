import Foundation
import GitOKAppCore
import GitOKCoreKit
import SwiftUI

public enum AppearanceSettingsPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "AppearanceSettingsPlugin",
        displayName: AppearanceSettingsPluginLocalization.string("AppearanceSettingsPlugin"),
        description: "",
        iconName: "paintbrush",
        order: 70,
        policy: .alwaysOn,
        tableName: AppearanceSettingsPluginLocalization.table
    )

    @MainActor
    public static func settingsPaneItems(context: GitOKPluginContext) -> [GitOKSettingsPaneItem] {
        [
            GitOKSettingsPaneItem(
                id: "appearance",
                title: AppearanceSettingsPluginLocalization.string("外观"),
                systemImage: "paintbrush",
                order: 70,
                view: AnyView(AppAppearanceSettingView())
            ),
        ]
    }
}

public enum AppearanceSettingsPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
