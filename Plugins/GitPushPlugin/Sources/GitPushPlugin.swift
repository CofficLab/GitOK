import Foundation
import GitOKCoreKit
import SwiftUI

public struct GitPushPlugin: GitOKPlugin {
    public static let shared = GitPushPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "GitPushPlugin",
        displayName: GitPushPluginLocalization.string("Git Sync"),
        description: GitPushPluginLocalization.string("Run Fetch, Pull, or Push based on branch state"),
        iconName: "arrow.triangle.2.circlepath",
        policy: .alwaysOn,
        tableName: GitPushPluginLocalization.table
    )

    private init() {}

    public func toolBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        guard context.isGitRepository, let projectURL = context.projectURL else { return nil }

        let trackingStatus = context.remoteTrackingStatus ?? GitOKRemoteTrackingStatus(
            ahead: 0, behind: 0, hasUpstream: false
        )

        return AnyView(GitPushButton(
            projectURL: projectURL,
            isGitRepository: context.isGitRepository,
            trackingStatus: trackingStatus,
            updateRemoteTracking: context.onRemoteTrackingUpdate
        ))
    }
}

public enum GitPushPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
