import Foundation
import GitOKCoreKit
import SwiftUI

public struct ReadmePlugin: GitOKPackagedPlugin {
    public static let shared = ReadmePlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "ReadmePlugin",
        displayName: PluginReadmeLocalization.string("Readme"),
        description: PluginReadmeLocalization.string("Provides README entry point in status bar"),
        iconName: "book",
        order: 9999,
        allowUserToggle: true,
        defaultEnabled: true,
        tableName: PluginReadmeLocalization.table
    )

    private init() {}

    @MainActor
    public func statusBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        guard let projectURL = context.projectURL else { return nil }
        return AnyView(ReadmeStatusIcon(projectURL: projectURL))
    }
}

public enum PluginReadmeLocalization {
    public static let table = "Readme"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
