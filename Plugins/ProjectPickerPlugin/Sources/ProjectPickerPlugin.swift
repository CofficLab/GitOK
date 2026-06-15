import Foundation
import GitOKCoreKit
import SwiftUI

public enum ProjectPickerPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "ProjectPickerPlugin",
        displayName: ProjectPickerPluginLocalization.string("ProjectPicker"),
        description: ProjectPickerPluginLocalization.string("项目选择器"),
        iconName: "folder",
        policy: .alwaysOn,
        tableName: ProjectPickerPluginLocalization.table
    )


    @MainActor
    public static func toolbarLeadingItems(context: GitOKPluginContext) -> [GitOKToolbarItem] {
        return [GitOKToolbarItem(id: metadata.id, view: AnyView(ProjectPickerView(
            projects: context.projects,
            selectedProjectURL: context.selectedProjectURL,
            isSidebarVisible: context.isSidebarVisible,
            selectProject: context.onProjectSelection
        )))]
    }

    @MainActor
    public static func pluginIntroductionView(context: GitOKPluginContext) -> AnyView? {
        Self.pluginIntroductionCard(
            footnote: "Shows the project picker in the toolbar for quick project switching."
        )
    }
}

public enum ProjectPickerPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
