import Foundation
import GitOKCoreKit
import SwiftUI

public struct OpenXcodePlugin: GitOKPackagedPlugin {
    public static let shared = OpenXcodePlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "OpenXcode",
        displayName: PluginOpenXcodeLocalization.string("Open Xcode"),
        description: PluginOpenXcodeLocalization.string("Open the current project folder in Xcode."),
        iconName: "hammer",
        order: 8402,
        allowUserToggle: true,
        defaultEnabled: false,
        tableName: PluginOpenXcodeLocalization.table
    )

    private init() {}

    public func toolBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        guard let projectURL = context.projectURL else { return nil }
        return AnyView(OpenXcodeButton(projectURL: projectURL))
    }
}

public enum PluginOpenXcodeLocalization {
    public static let table = "OpenXcode"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
