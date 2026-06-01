import Foundation
import GitOKCoreKit
import SwiftUI

public struct OpenFinderPlugin: GitOKPlugin {
    public static let shared = OpenFinderPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "OpenFinder",
        displayName: PluginOpenFinderLocalization.string("Open Finder"),
        description: PluginOpenFinderLocalization.string("Open the current project folder in Finder."),
        iconName: "folder",
        order: 8300,
        policy: .optIn,
        tableName: PluginOpenFinderLocalization.table
    )

    private init() {}

    public func toolBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        guard let projectURL = context.projectURL else { return nil }
        return AnyView(OpenFinderButton(projectURL: projectURL))
    }
}

public enum PluginOpenFinderLocalization {
    public static let table = "OpenFinder"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
