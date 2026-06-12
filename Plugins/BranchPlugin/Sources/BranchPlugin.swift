import Foundation
import GitOKCoreKit
import SwiftUI

public enum BranchPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "BranchPlugin",
        displayName: BranchPluginLocalization.string("Branch"),
        description: BranchPluginLocalization.string("Git 分支管理"),
        iconName: "arrow.triangle.branch",
        order: 10000,
        policy: .alwaysOn,
        tableName: BranchPluginLocalization.table
    )

    @MainActor
    public static func toolbarTrailingItems(context: GitOKPluginContext) -> [GitOKToolbarItem] {
        let pluginContext = toolBarContext(from: context)
        return [GitOKToolbarItem(id: metadata.id, view: AnyView(BranchPickerView(context: pluginContext)))]
    }

    @MainActor
    public static func statusBarLeadingItems(context: GitOKPluginContext) -> [GitOKStatusBarItem] {
        let pluginContext = BranchPluginContext(context)
        return [GitOKStatusBarItem(id: metadata.id, view: AnyView(BranchStatusTile(context: pluginContext)))]
    }

    @MainActor
    public static func toolBarContext(from context: GitOKPluginContext) -> BranchPluginContext {
        BranchPluginContext(context)
    }
}
