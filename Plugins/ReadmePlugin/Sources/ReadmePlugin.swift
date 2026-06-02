import Foundation
import GitOKCoreKit
import SwiftUI

public struct ReadmePlugin: GitOKPlugin {
    public static let shared = ReadmePlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "ReadmePlugin",
        displayName: ReadmePluginLocalization.string("Readme"),
        description: ReadmePluginLocalization.string("Provides README entry point in status bar"),
        iconName: "book",
        order: 9999,
        policy: .optIn,
        tableName: ReadmePluginLocalization.table
    )

    private init() {}

    @MainActor
    public func statusBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        guard let projectURL = context.projectURL else { return nil }
        return AnyView(ReadmeStatusIcon(projectURL: projectURL))
    }
}

public enum ReadmePluginLocalization {
    public static let table = "Readme"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
