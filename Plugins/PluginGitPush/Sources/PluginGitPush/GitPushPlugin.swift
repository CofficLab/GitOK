import Foundation
import GitOKCoreKit
import SwiftUI

public struct GitPushPlugin: GitOKPlugin {
    public static let shared = GitPushPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "GitPushPlugin",
        displayName: PluginGitPushLocalization.string("Git Sync"),
        description: PluginGitPushLocalization.string("根据分支状态执行 Fetch、Pull 或 Push"),
        iconName: "arrow.triangle.2.circlepath",
        policy: .optOut,
        tableName: PluginGitPushLocalization.table
    )

    private init() {}

    public func toolBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        guard let projectURL = context.projectURL else { return nil }

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

public enum PluginGitPushLocalization {
    public static let table = "GitPush"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
