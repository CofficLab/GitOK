import Foundation
import GitOKAppCore
import GitOKCoreKit
import SwiftUI

public enum GitRepositorySettingsPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "GitRepositorySettingsPlugin",
        displayName: GitRepositorySettingsPluginLocalization.string("GitRepositorySettingsPlugin"),
        description: "",
        iconName: "folder.badge.gearshape",
        order: 10,
        policy: .alwaysOn,
        tableName: GitRepositorySettingsPluginLocalization.table
    )

    @MainActor
    public static func settingsPaneItems(context: GitOKPluginContext) -> [GitOKSettingsPaneItem] {
        [
            GitOKSettingsPaneItem(
                id: "repository",
                title: GitRepositorySettingsPluginLocalization.string("仓库设置"),
                systemImage: "folder.badge.gearshape",
                order: 10,
                view: AnyView(RepositorySettingView())
            ),
        ]
    }
}

public enum GitRepositorySettingsPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
