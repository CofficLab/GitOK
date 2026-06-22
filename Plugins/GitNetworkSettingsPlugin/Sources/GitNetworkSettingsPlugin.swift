import Foundation
import GitOKAppCore
import GitOKCoreKit
import SwiftUI

public enum GitNetworkSettingsPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "GitNetworkSettingsPlugin",
        displayName: GitNetworkSettingsPluginLocalization.string("GitNetworkSettingsPlugin"),
        description: "",
        iconName: "network",
        order: 40,
        policy: .alwaysOn,
        tableName: GitNetworkSettingsPluginLocalization.table
    )

    @MainActor
    public static func settingsPaneItems(context: GitOKPluginContext) -> [GitOKSettingsPaneItem] {
        [
            GitOKSettingsPaneItem(
                id: "network",
                title: GitNetworkSettingsPluginLocalization.string("Network"),
                systemImage: "network",
                order: 40,
                view: AnyView(GitNetworkSettingView())
            ),
        ]
    }
}

public enum GitNetworkSettingsPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
