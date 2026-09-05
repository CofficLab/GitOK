import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderGitRepositoryWatch
import ProviderProjects
import ProviderStatusBar
import ProviderToolbar
import ProviderWorkspaceScene
import SwiftUI

// MARK: - Git Branch Status SuperPlugin

/// 分支状态插件：在状态栏显示当前分支名，并在工具栏右上角提供分支选择器
/// （对齐旧版 PluginGitBranch / GitBranchPlugin）。
@MainActor
public final class GitBranchStatusPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.git-branch-status", category: "GitBranchStatus")
    nonisolated public static let emoji = "🌿"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.git-branch-status"
    public let order = 32
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.git-branch-status",
        name: "Git Branch Status",
        description: "Show the current branch in the status bar and switch branches from the toolbar",
        category: .project,
        stage: .stable,
        policy: .alwaysOn
    )

    static let itemID = "com.coffic.gitok.plugin.git-branch-status.id"
    static let toolbarItemID = "com.coffic.gitok.plugin.git-branch-status.toolbar"

    private var sceneViewModel: WorkspaceSceneVisibilityViewModel?
    private var sceneObserver: GitBranchStatusSceneObserver?
    private var branchViewModel: GitBranchStatusViewModel?
    private var branchObserver: GitBranchStatusObserver?

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error("\(self.t)ProjectProviding not registered; skip branch status plugin")
            return
        }
        guard let scene = kernel.resolveProvider((any WorkspaceSceneProviding).self) else {
            Self.logger.error("\(self.t)WorkspaceSceneProviding not registered; skip scene wiring")
            return
        }

        let sceneViewModel = WorkspaceSceneVisibilityViewModel(targetScene: .git)
        self.sceneViewModel = sceneViewModel
        let sceneCapability = GitBranchStatusSceneCapabilityAdapter(scene: scene)
        self.sceneObserver = GitBranchStatusSceneObserver(capability: sceneCapability, viewModel: sceneViewModel)
        let gitWatch = kernel.resolveProvider((any GitRepositoryWatching).self)
        let branchCapability = GitBranchStatusCapabilityAdapter(projects: projects, gitWatch: gitWatch)
        let branchViewModel = GitBranchStatusViewModel()
        self.branchViewModel = branchViewModel
        self.branchObserver = GitBranchStatusObserver(capability: branchCapability, viewModel: branchViewModel)

        // 工具栏右上角：分支选择器（显示当前分支 + 切换分支）。
        if let toolbar = kernel.resolveProvider((any ToolbarProviding).self) {
            toolbar.addToolbarItems([
                ToolbarItem(
                    id: Self.toolbarItemID,
                    title: LumiPluginLocalization.string("Current Branch", bundle: .module),
                    placement: .trailing,
                    category: .project,
                    order: 40
                ) {
                    WorkspaceSceneVisibilityView(viewModel: sceneViewModel) {
                        BranchPickerView(projects: projects, viewModel: branchViewModel)
                    }
                },
            ])
        } else {
            Self.logger.error("\(self.t)ToolbarProviding not registered; skip branch picker item")
        }

        // 状态栏左侧：当前分支名（点击弹出分支管理面板）。
        guard let statusBar = kernel.resolveProvider((any StatusBarProviding).self) else {
            Self.logger.error("\(self.t)StatusBarProviding not registered; skip branch status item")
            return
        }
        statusBar.addStatusBarItems([
            StatusBarItem(
                id: Self.itemID,
                title: LumiPluginLocalization.string("Current Branch", bundle: .module),
                placement: .leading,
                order: 15
            ) {
                WorkspaceSceneVisibilityView(viewModel: sceneViewModel) {
                    BranchStatusTile(projects: projects, viewModel: branchViewModel)
                }
            },
        ])
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        sceneObserver?.cancel()
        sceneObserver = nil
        sceneViewModel = nil
        branchObserver?.cancel()
        branchObserver = nil
        branchViewModel = nil
        kernel.resolveProvider((any StatusBarProviding).self)?
            .removeStatusBarItems(ids: [Self.itemID])
        kernel.resolveProvider((any ToolbarProviding).self)?
            .removeToolbarItems(ids: [Self.toolbarItemID])
    }
}
