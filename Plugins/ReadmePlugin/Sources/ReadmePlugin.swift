import Foundation
import GitOKCoreKit
import SwiftUI

public enum ReadmePlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "ReadmePlugin",
        displayName: ReadmePluginLocalization.string("Readme"),
        description: ReadmePluginLocalization.string("Provides README entry point in status bar"),
        iconName: "book",
        order: 9999,
        policy: .optIn,
        tableName: ReadmePluginLocalization.table
    )


    @MainActor
    public static func statusBarTrailingItems(context: GitOKPluginContext) -> [GitOKStatusBarItem] {
        guard let projectURL = context.projectURL else { return [] }
        return [GitOKStatusBarItem(id: metadata.id, view: AnyView(ReadmeStatusIcon(projectURL: projectURL)))]
    }
}

public enum ReadmePluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
