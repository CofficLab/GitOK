import Foundation
import GitOKCoreKit
import SwiftUI

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
