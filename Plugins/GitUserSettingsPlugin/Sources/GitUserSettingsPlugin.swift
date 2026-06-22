import Foundation
import GitOKAppCore
import GitOKCoreKit
import SwiftUI

public enum GitUserSettingsPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "GitUserSettingsPlugin",
        displayName: GitUserSettingsPluginLocalization.string("GitUserSettingsPlugin"),
        description: "",
        iconName: "person.circle",
        order: 20,
        policy: .alwaysOn,
        tableName: GitUserSettingsPluginLocalization.table
    )

    @MainActor
    public static func settingsPaneItems(context: GitOKPluginContext) -> [GitOKSettingsPaneItem] {
        [
            GitOKSettingsPaneItem(
                id: "userInfo",
                title: GitUserSettingsPluginLocalization.string("User Information"),
                systemImage: "person.circle",
                order: 20,
                view: AnyView(GitUserInfoSettingView())
            ),
        ]
    }
}

public enum GitUserSettingsPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
