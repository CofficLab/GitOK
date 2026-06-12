import Foundation
import GitOKAppCore
import GitOKCoreKit
import SwiftUI

public enum RepositorySettingsPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "RepositorySettingsPlugin",
        displayName: RepositorySettingsPluginLocalization.string("RepositorySettingsPlugin"),
        description: "",
        iconName: "folder.badge.gearshape",
        order: 10,
        policy: .alwaysOn,
        tableName: RepositorySettingsPluginLocalization.table
    )

    @MainActor
    public static func settingsPaneItems(context: GitOKPluginContext) -> [GitOKSettingsPaneItem] {
        [
            GitOKSettingsPaneItem(
                id: "repository",
                title: RepositorySettingsPluginLocalization.string("仓库设置"),
                systemImage: "folder.badge.gearshape",
                order: 10,
                view: AnyView(RepositorySettingView())
            ),
        ]
    }
}

public enum RepositorySettingsPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
