import Foundation
import GitOKAppCore
import GitOKCoreKit
import SwiftUI

public enum GitCommitStyleSettingsPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "GitCommitStyleSettingsPlugin",
        displayName: GitCommitStyleSettingsPluginLocalization.string("GitCommitStyleSettingsPlugin"),
        description: "",
        iconName: "text.alignleft",
        order: 30,
        policy: .alwaysOn,
        tableName: GitCommitStyleSettingsPluginLocalization.table
    )

    @MainActor
    public static func settingsPaneItems(context: GitOKPluginContext) -> [GitOKSettingsPaneItem] {
        [
            GitOKSettingsPaneItem(
                id: "commitStyle",
                title: GitCommitStyleSettingsPluginLocalization.string("Commit Style"),
                systemImage: "text.alignleft",
                order: 30,
                view: AnyView(CommitStyleSettingView())
            ),
        ]
    }
}

public enum GitCommitStyleSettingsPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
