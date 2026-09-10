import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderGitRepositoryWatch
import ProviderGit
import ProviderProjects
import ProviderToolbar
import ProviderWorkspaceScene
import SwiftUI
import ProviderDocsView

// MARK: - Git Branch Status SuperPlugin

/// 分支状态插件：在工具栏右上角提供分支选择器
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
        description: "Switch branches from the toolbar",
        category: .project,
        stage: .stable,
        policy: .alwaysOn
    )

    static let toolbarItemID = "com.coffic.gitok.plugin.git-branch-status.toolbar"

    private var sceneViewModel: WorkspaceSceneVisibilityViewModel?
    private var sceneObserver: GitBranchStatusSceneObserver?
    private var branchViewModel: GitBranchStatusViewModel?
    private var branchObserver: GitBranchStatusObserver?

    public init() {}

    public func onRegister(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any DocsViewProviding).self)?.addAbout(
            DocsEntry(id: id, name: metadata.name) { GitBranchStatusAboutView() }
        )
    }

    public func onUnregister(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any DocsViewProviding).self)?.removeEntries(id: id)
    }

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error("\(self.t)ProjectProviding not registered; skip branch status plugin")
            return
        }
        guard let git = kernel.resolveProvider((any GitProviding).self) else {
            Self.logger.error("\(self.t)GitProviding not registered; skip branch status plugin")
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
        self.branchObserver = GitBranchStatusObserver(
            capability: branchCapability,
            git: git,
            viewModel: branchViewModel
        )

        // 工具栏右上角：分支选择器（显示当前分支 + 切换分支）。
        if let toolbar = kernel.resolveProvider((any ToolbarProviding).self) {
            toolbar.addToolbarItems([
                ToolbarItem(
                    id: Self.toolbarItemID,
                    title: LumiPluginLocalization.string("Current Branch", bundle: .module),
                    placement: .trailing,
                    category: .project,
                    // 负 order 使其排在 trailing 组所有项（OpenIn 最小 10、
                    // 设置按钮 150）之前，位于工具栏右侧最左一个。
                    order: -50
                ) {
                    WorkspaceSceneVisibilityView(viewModel: sceneViewModel) {
                        BranchPickerView(projects: projects, git: git, viewModel: branchViewModel)
                    }
                },
            ])
        } else {
            Self.logger.error("\(self.t)ToolbarProviding not registered; skip branch picker item")
        }

        // 分支选择器仅保留在工具栏右侧；状态栏不再提供切换入口。
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        sceneObserver?.cancel()
        sceneObserver = nil
        sceneViewModel = nil
        branchObserver?.cancel()
        branchObserver = nil
        branchViewModel = nil
        kernel.resolveProvider((any ToolbarProviding).self)?
            .removeToolbarItems(ids: [Self.toolbarItemID])
    }
}
