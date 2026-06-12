import Foundation
import GitOKCoreKit
import SwiftUI

public enum SmartMergePlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "SmartMergePlugin",
        displayName: SmartMergePluginLocalization.string("SmartMerge"),
        description: SmartMergePluginLocalization.string("智能合并工具"),
        iconName: "arrow.merge",
        policy: .optIn,
        tableName: SmartMergePluginLocalization.table
    )


    @MainActor
    public static func statusBarTrailingItems(context: GitOKPluginContext) -> [GitOKStatusBarItem] {
        guard let projectURL = context.projectURL else { return [] }
        return [GitOKStatusBarItem(id: metadata.id, view: AnyView(SmartMergeStatusTile(projectURL: projectURL, isGitRepository: context.isGitRepository)))]
    }
}

public enum SmartMergePluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
