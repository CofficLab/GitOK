import Foundation
import GitOKCoreKit
import SwiftUI

public enum UnpushedStatusPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "UnpushedStatusPlugin",
        displayName: UnpushedStatusPluginLocalization.string("Unpushed Status"),
        description: UnpushedStatusPluginLocalization.string("Display unpushed commit count"),
        iconName: "arrow.up.circle",
        order: 25,
        policy: .alwaysOn,
        tableName: UnpushedStatusPluginLocalization.table
    )


    @MainActor
    public static func rootOverlay(context: GitOKPluginContext, content: AnyView) -> AnyView? {
        return         AnyView(UnpushedStatusRootView(
            content: content,
            projectURL: context.projectURL,
            updateUnpushedCommits: context.onUnpushedCommitsUpdate,
            updateRemoteTracking: context.onRemoteTrackingUpdate
        ))
    }
}

public enum UnpushedStatusPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
