import Foundation
import GitOKCoreKit
import SwiftUI

public enum OpenCursorPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "OpenCursor",
        displayName: OpenCursorPluginLocalization.string("Open Cursor"),
        description: OpenCursorPluginLocalization.string("Open the current project folder in Cursor."),
        iconName: "cursor.rays",
        order: 8401,
        policy: .optIn,
        tableName: OpenCursorPluginLocalization.table
    )


    @MainActor
    public static func toolbarTrailingItems(context: GitOKPluginContext) -> [GitOKToolbarItem] {
        guard let projectURL = context.projectURL else { return [] }
        return [GitOKToolbarItem(id: metadata.id, view: AnyView(OpenCursorButton(projectURL: projectURL)))]
    }

    @MainActor
    public static func pluginIntroductionView(context: GitOKPluginContext) -> AnyView? {
        Self.pluginIntroductionCard(
            footnote: CursorProjectLauncher.isInstalled ? nil : "Cursor is not installed on this Mac."
        )
    }
}

public enum OpenCursorPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
