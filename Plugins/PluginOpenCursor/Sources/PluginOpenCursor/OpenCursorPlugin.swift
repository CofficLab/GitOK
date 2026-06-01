import Foundation
import GitOKCoreKit
import SwiftUI

public struct OpenCursorPlugin: GitOKPlugin {
    public static let shared = OpenCursorPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "OpenCursor",
        displayName: PluginOpenCursorLocalization.string("Open Cursor"),
        description: PluginOpenCursorLocalization.string("Open the current project folder in Cursor."),
        iconName: "cursor.rays",
        order: 8401,
        policy: .optIn,
        tableName: PluginOpenCursorLocalization.table
    )

    private init() {}

    public func toolBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        guard let projectURL = context.projectURL else { return nil }
        return AnyView(OpenCursorButton(projectURL: projectURL))
    }
}

public enum PluginOpenCursorLocalization {
    public static let table = "OpenCursor"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
