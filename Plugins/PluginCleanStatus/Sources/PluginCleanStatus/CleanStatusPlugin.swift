import Foundation
import GitOKPluginKit
import SwiftUI

/// CleanStatusPlugin 内部使用的上下文，由 rootView 中从 Environment 捕获后传入。
///
/// 所有子视图通过此结构体获取内核数据，不再直接依赖 SwiftUI Environment。
public struct CleanStatusPluginContext: Sendable {
    public let projectURL: URL?
    public let updateCleanStatus: @Sendable @MainActor (Bool) -> Void

    public init(
        projectURL: URL? = nil,
        updateCleanStatus: @escaping @Sendable @MainActor (Bool) -> Void = { _ in }
    ) {
        self.projectURL = projectURL
        self.updateCleanStatus = updateCleanStatus
    }
}

public struct CleanStatusPlugin: GitOKPackagedPlugin {
    public static let shared = CleanStatusPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "CleanStatusPlugin",
        displayName: PluginCleanStatusLocalization.string("Clean Status"),
        description: PluginCleanStatusLocalization.string("Track whether project is clean (no uncommitted changes)"),
        iconName: "checkmark.circle",
        order: 24,
        allowUserToggle: false,
        defaultEnabled: true,
        tableName: PluginCleanStatusLocalization.table
    )

    private init() {}

    @MainActor
    public func rootView(_ content: AnyView) -> AnyView? {
        AnyView(CleanStatusRootView(content: content))
    }
}

public enum PluginCleanStatusLocalization {
    public static let table = "CleanStatus"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
