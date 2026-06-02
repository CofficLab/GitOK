import Foundation
import GitOKCoreKit
import SwiftUI

/// BranchPlugin 内部使用的上下文，由 GitOKPluginContext 转换而来。
///
/// 所有子视图通过此结构体获取内核数据，不再依赖 SwiftUI Environment。
public struct BranchPluginContext: Sendable {
    public let projectURL: URL?
    public let branchName: String?
    public let isGitRepository: Bool

    public init(
        projectURL: URL? = nil,
        branchName: String? = nil,
        isGitRepository: Bool = false
    ) {
        self.projectURL = projectURL
        self.branchName = branchName
        self.isGitRepository = isGitRepository
    }

    @MainActor
    public init(_ context: GitOKPluginContext) {
        self.projectURL = context.projectURL
        self.branchName = context.branchName
        self.isGitRepository = context.isGitRepository
    }
}

public struct BranchPlugin: GitOKPlugin {
    public static let shared = BranchPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "BranchPlugin",
        displayName: BranchPluginLocalization.string("Branch"),
        description: BranchPluginLocalization.string("Git 分支管理"),
        iconName: "arrow.triangle.branch",
        order: 22,
        policy: .optIn,
        tableName: BranchPluginLocalization.table
    )

    private init() {}

    public func toolBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        AnyView(BranchPickerView(context: BranchPluginContext()))
    }

    @MainActor
    public func statusBarLeadingView(context: GitOKPluginContext) -> AnyView? {
        let pluginContext = BranchPluginContext(context)
        return AnyView(BranchStatusTile(context: pluginContext))
    }
}

public enum BranchPluginLocalization {
    public static let table = "GitBranch"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
