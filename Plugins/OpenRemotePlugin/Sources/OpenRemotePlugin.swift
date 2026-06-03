import Foundation
import GitOKCoreKit
import SwiftUI

public struct OpenRemotePlugin: GitOKPlugin {
    public static let shared = OpenRemotePlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "OpenRemote",
        displayName: OpenRemotePluginLocalization.string("Open Remote"),
        description: OpenRemotePluginLocalization.string("Open the current project's remote repository link."),
        iconName: "link",
        order: 8407,
        policy: .optIn,
        tableName: OpenRemotePluginLocalization.table
    )

    private init() {}

    public func toolBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        guard let projectURL = context.projectURL else { return nil }
        return AnyView(OpenRemoteButton(projectURL: projectURL))
    }
}

public enum OpenRemotePluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
