import Foundation
import GitOKAppCore
import GitOKCoreKit
import SwiftUI

public enum CommitStyleSettingsPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "CommitStyleSettingsPlugin",
        displayName: CommitStyleSettingsPluginLocalization.string("CommitStyleSettingsPlugin"),
        description: "",
        iconName: "text.alignleft",
        order: 30,
        policy: .alwaysOn,
        tableName: CommitStyleSettingsPluginLocalization.table
    )

    @MainActor
    public static func settingsPaneItems(context: GitOKPluginContext) -> [GitOKSettingsPaneItem] {
        [
            GitOKSettingsPaneItem(
                id: "commitStyle",
                title: CommitStyleSettingsPluginLocalization.string("Commit 风格"),
                systemImage: "text.alignleft",
                order: 30,
                view: AnyView(CommitStyleSettingView())
            ),
        ]
    }
}

public enum CommitStyleSettingsPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
