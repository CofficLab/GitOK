import Foundation
import GitOKCoreKit
import SwiftUI

public struct OpenXcodePlugin: GitOKPlugin {
    public static let shared = OpenXcodePlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "OpenXcode",
        displayName: OpenXcodePluginLocalization.string("Open Xcode"),
        description: OpenXcodePluginLocalization.string("Open the current project folder in Xcode."),
        iconName: "hammer",
        order: 8402,
        policy: .optIn,
        tableName: OpenXcodePluginLocalization.table
    )

    private init() {}

    public func toolBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        guard let projectURL = context.projectURL else { return nil }
        return AnyView(OpenXcodeButton(projectURL: projectURL))
    }
}

public enum OpenXcodePluginLocalization {
    public static let table = "OpenXcode"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
