import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderContentView
import ProviderGitRepositoryWatch
import ProviderProjects
import ProviderWorkspaceScene
import SwiftUI

// MARK: - Worktree Clean SuperPlugin

/// 工作区干净视图插件。
///
/// 从 CommitDetail 插件中独立出来：当「当前项目已打开 + 未选中 commit +
/// 工作区无未提交变更」时，通过 `ContentViewProviding` 向主内容区贡献一块
/// 「工作区干净」视图（绿色对勾提示 + 仓库信息 + Git 用户配置）。
///
/// 状态由插件自有 ViewModel 持有；外部事件（项目 / commit 选择、仓库与工作区
/// 数据变化）由 `WorktreeCleanObserver` 翻译进 ViewModel。其余情况渲染
/// `EmptyView` 不占用布局——工作区变更列表仍由 CommitDetail 插件展示，
/// 二者内容块互斥。
@MainActor
public final class WorktreeCleanPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.worktree-clean", category: "WorktreeClean")
    nonisolated public static let emoji = "✅"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.worktree-clean"
    /// 依赖项目 Provider 先启动（干净视图需要读取当前项目）。
    public let order = 22
    public let dependencies = ["com.coffic.lumi.plugin.projects"]
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.worktree-clean",
        name: "Worktree Clean",
        description: "Show working-tree clean state (repo info & git user config) when there are no uncommitted changes",
        category: .project,
        stage: .stable,
        policy: .required
    )

    /// 插件自有 ViewModel：由外部 Observer 驱动，视图只绑定它。
    private var viewModel: WorktreeCleanViewModel?
    /// 插件级外部 Observer：装配阶段创建并持有，卸载时取消。
    private var observer: WorktreeCleanObserver?
    private var sceneViewModel: WorkspaceSceneVisibilityViewModel?
    private var sceneObserver: WorktreeCleanSceneObserver?

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let contentView = kernel.resolveProvider((any ContentViewProviding).self) else {
            Self.logger.error("\(self.t)ContentViewProviding not registered; skip content injection")
            return
        }
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error("\(self.t)ProjectProviding not registered; skip content injection")
            return
        }

        guard let scene = kernel.resolveProvider((any WorkspaceSceneProviding).self) else {
            Self.logger.error("\(self.t)WorkspaceSceneProviding not registered; skip scene wiring")
            return
        }

        // GitRepositoryWatching 可选依赖：感知外部工作区文件变化
        // （如其他编辑器把文件改干净 / 改脏后，干净视图据此刷新）。
        let gitWatch = kernel.resolveProvider((any GitRepositoryWatching).self)

        // 装配阶段创建自有 ViewModel 与外部 Observer（Lumi 插件规范：
        // 插件入口是插件级外部监听的唯一持有者）。随后显式同步一次初始快照。
        let viewModel = WorktreeCleanViewModel()
        self.viewModel = viewModel
        observer = WorktreeCleanObserver(
            projects: projects,
            gitWatch: gitWatch,
            onProjectChanged: { [weak viewModel, weak projects] in
                guard let projects else { return }
                viewModel?.handleProjectChanged(
                    project: projects.currentProject,
                    hasSelectedCommit: projects.currentCommit != nil
                )
            },
            onDataChanged: { [weak viewModel] in
                viewModel?.handleDataChanged()
            }
        )
        viewModel.handleProjectChanged(
            project: projects.currentProject,
            hasSelectedCommit: projects.currentCommit != nil
        )

        let sceneViewModel = WorkspaceSceneVisibilityViewModel(targetScene: .git)
        self.sceneViewModel = sceneViewModel
        self.sceneObserver = WorktreeCleanSceneObserver(scene: scene, viewModel: sceneViewModel)

        // 作为主内容区的一块贡献（与 CommitDetail 同层；二者互斥，不会同时占位）。
        contentView.addContentView(
            AnyView(
                WorkspaceSceneVisibilityView(viewModel: sceneViewModel) {
                    WorktreeCleanView(viewModel: viewModel)
                }
                    // Debug 构建下左下角叠加插件名 badge，便于识别内容区来源。
                    .debugPluginBadge(metadata.name)
            ),
            id: "\(id).content",
            order: 20
        )
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        sceneObserver?.cancel()
        sceneObserver = nil
        sceneViewModel = nil
        observer?.cancel()
        observer = nil
        viewModel = nil
        kernel.resolveProvider((any ContentViewProviding).self)?
            .removeContentView(id: "\(id).content")
    }
}
