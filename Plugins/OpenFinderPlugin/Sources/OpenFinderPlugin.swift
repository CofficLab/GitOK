import Foundation
import GitOKCoreKit
import SwiftUI

public struct OpenFinderPlugin: GitOKPlugin {
    public static let shared = OpenFinderPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "OpenFinder",
        displayName: OpenFinderPluginLocalization.string("Open Finder"),
        description: OpenFinderPluginLocalization.string("Open the current project folder in Finder."),
        iconName: "folder",
        order: 8300,
        policy: .optIn,
        tableName: OpenFinderPluginLocalization.table
    )

    private init() {}

    public func toolBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        guard let projectURL = context.projectURL else { return nil }
        return AnyView(OpenFinderButton(projectURL: projectURL))
    }
}

public enum OpenFinderPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
