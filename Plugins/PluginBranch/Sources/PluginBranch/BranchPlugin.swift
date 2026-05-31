import Foundation
import GitOKPluginKit
import SwiftUI

public struct BranchPlugin: GitOKPackagedPlugin {
    public static let shared = BranchPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "BranchPlugin",
        displayName: PluginBranchLocalization.string("Branch"),
        description: PluginBranchLocalization.string("Git 分支管理"),
        iconName: "arrow.triangle.branch",
        order: 22,
        allowUserToggle: true,
        defaultEnabled: true,
        tableName: PluginBranchLocalization.table
    )

    private init() {}

    public func toolBarTrailingView() -> AnyView? {
        AnyView(BranchPickerView())
    }

    @MainActor
    public func statusBarLeadingView(context: GitOKPluginContext) -> AnyView? {
        AnyView(BranchStatusTile())
    }
}

public enum PluginBranchLocalization {
    public static let table = "GitBranch"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
