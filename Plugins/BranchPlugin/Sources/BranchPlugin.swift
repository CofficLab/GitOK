import Foundation
import GitOKCoreKit
import SwiftUI

public enum BranchPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "BranchPlugin",
        displayName: BranchPluginLocalization.string("Branch"),
        description: BranchPluginLocalization.string("Git Branch Management"),
        iconName: "arrow.triangle.branch",
        order: 10000,
        policy: .alwaysOn,
        tableName: BranchPluginLocalization.table
    )

    @MainActor
    public static func toolbarTrailingItems(context: GitOKPluginContext) -> [GitOKToolbarItem] {
        let pluginContext = BranchPluginContext(context)
        let monitor = BranchMonitor(
            projectURL: context.projectURL,
            isGitRepository: context.isGitRepository
        )
        let picker = BranchPickerView(context: pluginContext)
            .environment(\.branchMonitor, monitor)
            .injectServiceIfNeeded(projectURL: context.projectURL)
        return [GitOKToolbarItem(id: metadata.id, view: AnyView(picker))]
    }

    @MainActor
    public static func statusBarLeadingItems(context: GitOKPluginContext) -> [GitOKStatusBarItem] {
        let pluginContext = BranchPluginContext(context)
        let monitor = BranchMonitor(
            projectURL: context.projectURL,
            isGitRepository: context.isGitRepository
        )
        let tile = BranchStatusTile(context: pluginContext)
            .environment(\.branchMonitor, monitor)
            .injectServiceIfNeeded(projectURL: context.projectURL)
        return [GitOKStatusBarItem(id: metadata.id, view: AnyView(tile))]
    }

    @MainActor
    public static func toolBarContext(from context: GitOKPluginContext) -> BranchPluginContext {
        BranchPluginContext(context)
    }

    @MainActor
    public static func pluginIntroductionView(context: GitOKPluginContext) -> AnyView? {
        Self.pluginIntroductionCard(
            footnote: "Adds a branch picker in the toolbar and a branch status tile in the status bar."
        )
    }
}

extension View {
    @MainActor
    @ViewBuilder
    func injectServiceIfNeeded(projectURL: URL?) -> some View {
        if let url = projectURL {
            self.environment(\.branchService, LiveBranchService(repositoryURL: url))
        } else {
            self
        }
    }
}
