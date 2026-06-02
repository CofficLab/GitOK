import Foundation
import GitOKCoreKit
import SwiftUI

public struct OpenAntigravityPlugin: GitOKPlugin {
    public static let shared = OpenAntigravityPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "OpenAntigravity",
        displayName: OpenAntigravityPluginLocalization.string("Open Antigravity"),
        description: OpenAntigravityPluginLocalization.string("Open the current project folder in Antigravity."),
        iconName: "paperplane",
        order: 8406,
        policy: .optIn,
        tableName: OpenAntigravityPluginLocalization.table
    )

    private init() {}

    public func toolBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        guard let projectURL = context.projectURL else { return nil }
        return AnyView(OpenAntigravityButton(projectURL: projectURL))
    }
}

public enum OpenAntigravityPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
