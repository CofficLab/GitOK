import Foundation
import GitOKPluginKit
import SwiftUI

public struct ProjectPickerPlugin: GitOKPackagedPlugin {
    public static let shared = ProjectPickerPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "ProjectPickerPlugin",
        displayName: PluginProjectPickerLocalization.string("ProjectPicker"),
        description: PluginProjectPickerLocalization.string("项目选择器"),
        iconName: "folder",
        allowUserToggle: false,
        defaultEnabled: true,
        tableName: PluginProjectPickerLocalization.table
    )

    private init() {}

    public func toolBarLeadingView(context: GitOKPluginContext) -> AnyView? {
        AnyView(ProjectPickerView())
    }
}

public enum PluginProjectPickerLocalization {
    public static let table = "ProjectPicker"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
