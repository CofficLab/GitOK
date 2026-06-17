import Foundation
import GitOKCoreKit
import SwiftUI

public enum GitUnpushedStatusPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "GitUnpushedStatusPlugin",
        displayName: GitUnpushedStatusPluginLocalization.string("Unpushed Status"),
        description: GitUnpushedStatusPluginLocalization.string("Display unpushed commit count"),
        iconName: "arrow.up.circle",
        order: 25,
        policy: .alwaysOn,
        tableName: GitUnpushedStatusPluginLocalization.table
    )

    public static var introductionContentKind: GitOKPluginAboutContentKind { .statusBar }


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

public enum GitUnpushedStatusPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
