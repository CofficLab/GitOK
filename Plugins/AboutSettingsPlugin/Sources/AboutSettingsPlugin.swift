import Foundation
import GitOKAppCore
import GitOKCoreKit
import SwiftUI

public enum AboutSettingsPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "AboutSettingsPlugin",
        displayName: AboutSettingsPluginLocalization.string("AboutSettingsPlugin"),
        description: "",
        iconName: "info.circle",
        order: 90,
        policy: .alwaysOn,
        tableName: AboutSettingsPluginLocalization.table
    )

    @MainActor
    public static func settingsPaneItems(context: GitOKPluginContext) -> [GitOKSettingsPaneItem] {
        [
            GitOKSettingsPaneItem(
                id: "releaseNotes",
                title: AboutSettingsPluginLocalization.string("更新"),
                systemImage: "arrow.triangle.2.circlepath",
                order: 50,
                view: AnyView(ReleaseNotesSettingView())
            ),
            GitOKSettingsPaneItem(
                id: "about",
                title: AboutSettingsPluginLocalization.string("关于"),
                systemImage: "info.circle",
                order: 90,
                view: AnyView(AboutView())
            ),
        ]
    }
}

public enum AboutSettingsPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
