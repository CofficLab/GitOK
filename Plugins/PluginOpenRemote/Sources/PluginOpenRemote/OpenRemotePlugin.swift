import Foundation
import GitOKPluginKit
import SwiftUI

public struct OpenRemotePlugin: GitOKPackagedPlugin {
    public static let shared = OpenRemotePlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "OpenRemote",
        displayName: PluginOpenRemoteLocalization.string("Open Remote"),
        description: PluginOpenRemoteLocalization.string("Open the current project's remote repository link."),
        iconName: "link",
        order: 8407,
        allowUserToggle: true,
        defaultEnabled: true,
        tableName: PluginOpenRemoteLocalization.table
    )

    private init() {}

    public func toolBarTrailingView() -> AnyView? {
        AnyView(OpenRemoteButton())
    }
}

public enum PluginOpenRemoteLocalization {
    public static let table = "OpenRemote"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
