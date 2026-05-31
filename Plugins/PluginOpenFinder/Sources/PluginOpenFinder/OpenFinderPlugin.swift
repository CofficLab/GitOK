import Foundation
import GitOKPluginKit
import SwiftUI

public struct OpenFinderPlugin: GitOKPackagedPlugin {
    public static let shared = OpenFinderPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "OpenFinder",
        displayName: PluginOpenFinderLocalization.string("Open Finder"),
        description: PluginOpenFinderLocalization.string("Open the current project folder in Finder."),
        iconName: "folder",
        order: 8300,
        allowUserToggle: true,
        defaultEnabled: true,
        tableName: PluginOpenFinderLocalization.table
    )

    private init() {}

    public func toolBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        AnyView(OpenFinderButton())
    }
}

public enum PluginOpenFinderLocalization {
    public static let table = "OpenFinder"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
