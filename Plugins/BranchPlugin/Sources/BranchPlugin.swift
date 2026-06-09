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
        order: 10000,
        policy: .alwaysOn,
        tableName: BranchPluginLocalization.table
    )

    private init() {}

    @MainActor
    public func toolBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        let pluginContext = Self.toolBarContext(from: context)
        return AnyView(BranchPickerView(context: pluginContext))
    }

    @MainActor
    public func statusBarLeadingView(context: GitOKPluginContext) -> AnyView? {
        let pluginContext = BranchPluginContext(context)
        return AnyView(BranchStatusTile(context: pluginContext))
    }

    @MainActor
    static func toolBarContext(from context: GitOKPluginContext) -> BranchPluginContext {
        BranchPluginContext(context)
    }
}

public enum BranchPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
