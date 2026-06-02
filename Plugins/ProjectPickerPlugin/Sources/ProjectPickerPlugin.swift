import Foundation
import GitOKCoreKit
import SwiftUI

public struct ProjectPickerPlugin: GitOKPlugin {
    public static let shared = ProjectPickerPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "ProjectPickerPlugin",
        displayName: ProjectPickerPluginLocalization.string("ProjectPicker"),
        description: ProjectPickerPluginLocalization.string("项目选择器"),
        iconName: "folder",
        policy: .alwaysOn,
        tableName: ProjectPickerPluginLocalization.table
    )

    private init() {}

    public func toolBarLeadingView(context: GitOKPluginContext) -> AnyView? {
        AnyView(ProjectPickerView(
            projects: context.projects,
            selectedProjectURL: context.selectedProjectURL,
            isSidebarVisible: context.isSidebarVisible,
            selectProject: context.onProjectSelection
        ))
    }
}

public enum ProjectPickerPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
