import Foundation
import GitOKCoreKit
import SwiftUI

public struct OpenCursorPlugin: GitOKPlugin {
    public static let shared = OpenCursorPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "OpenCursor",
        displayName: OpenCursorPluginLocalization.string("Open Cursor"),
        description: OpenCursorPluginLocalization.string("Open the current project folder in Cursor."),
        iconName: "cursor.rays",
        order: 8401,
        policy: .optIn,
        tableName: OpenCursorPluginLocalization.table
    )

    private init() {}

    public func toolBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        guard CursorProjectLauncher.isInstalled, let projectURL = context.projectURL else { return nil }
        return AnyView(OpenCursorButton(projectURL: projectURL))
    }
}

public enum OpenCursorPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
