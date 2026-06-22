import Foundation
import GitOKAppCore
import GitOKCoreKit
import SwiftUI

public enum DiagnosticsSettingsPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "DiagnosticsSettingsPlugin",
        displayName: DiagnosticsSettingsPluginLocalization.string("DiagnosticsSettingsPlugin"),
        description: "",
        iconName: "stethoscope",
        order: 60,
        policy: .alwaysOn,
        tableName: DiagnosticsSettingsPluginLocalization.table
    )

    @MainActor
    public static func settingsPaneItems(context: GitOKPluginContext) -> [GitOKSettingsPaneItem] {
        [
            GitOKSettingsPaneItem(
                id: "diagnostics",
                title: DiagnosticsSettingsPluginLocalization.string("Diagnostics"),
                systemImage: "stethoscope",
                order: 60,
                view: AnyView(DiagnosticsSettingView())
            ),
        ]
    }
}

public enum DiagnosticsSettingsPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
