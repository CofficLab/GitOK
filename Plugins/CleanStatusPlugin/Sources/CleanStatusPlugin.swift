import Foundation
import GitOKCoreKit
import SwiftUI

public enum CleanStatusPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "CleanStatusPlugin",
        displayName: CleanStatusPluginLocalization.string("Clean Status"),
        description: CleanStatusPluginLocalization.string("Track whether project is clean (no uncommitted changes)"),
        iconName: "checkmark.circle",
        order: 24,
        policy: .alwaysOn,
        tableName: CleanStatusPluginLocalization.table
    )

    public static var introductionContentKind: GitOKPluginAboutContentKind { .statusBar }


    @MainActor
    public static func rootOverlay(context: GitOKPluginContext, content: AnyView) -> AnyView? {
        return         AnyView(CleanStatusRootView(
            content: content,
            projectURL: context.projectURL,
            updateCleanStatus: context.onCleanStatusUpdate
        ))
    }
}

public enum CleanStatusPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
