import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderContentView
import ProviderProjects
import SwiftUI

// MARK: - Commit Detail SuperPlugin

/// Commit 详情插件
///
/// 在 `onBoot` 阶段解析 `ProjectProviding` 与 `ContentViewProviding`，
/// 通过 ContentView 槽位（RootView 的主内容入口）注册主内容视图的一块：
/// 装配阶段创建自有 `CommitDetailViewModel` 与插件级 `CommitDetailObserver`；
/// 当 commit 列表（侧边栏 Rail）选中某条 commit、或仓库数据变化（提交 / 推送 /
/// 分支切换）后，Observer 把外部事件翻译进 ViewModel，驱动本块展示该 commit
/// 的变动（文件列表 + unified diff）或刷新工作区列表。
///
/// 「当前 commit / 当前文件 / 当前 commit 下的变动的文件」由 `ProjectProviding`
/// 统一维护，本插件只消费；提交表单由 PluginCommitForm 作为另一块内容贡献
/// （VStack 中 order 较小置顶），本插件不再内嵌表单。
///
/// 遵循 Lumi 架构：RootView 通过 `ContentViewProviding` 提供主内容槽位，
/// 插件在装配阶段通过 `addContentView` 注入自己的内容块；插件入口是
/// 插件级外部监听的唯一持有者（`Observers` 目录）。
@MainActor
public final class CommitDetailPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.commit-detail", category: "CommitDetail")
    nonisolated public static let emoji = "🔍"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.commit-detail"
    /// 依赖项目与 commit 列表先启动（选中状态由列表写入）。
    public let order = 21
    public let dependencies = ["com.coffic.lumi.plugin.projects", "com.coffic.gitok.plugin.commit-list"]
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.commit-detail",
        name: "Commit Detail",
        description: "Main content view showing the changes of the selected commit",
        category: .project,
        stage: .stable,
        policy: .required
    )

    /// 插件自有 ViewModel：由外部 Observer 驱动，视图只绑定它。
    private var viewModel: CommitDetailViewModel?
    /// 插件级外部 Observer：装配阶段创建并持有，卸载时取消。
    private var observer: CommitDetailObserver?

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

        // 装配阶段创建自有 ViewModel 与外部 Observer（Lumi 插件规范：
        // 插件入口是插件级外部监听的唯一持有者）。随后显式同步一次初始快照，
        // 避免注册时机导致 UI 永久使用默认值。
        let viewModel = CommitDetailViewModel()
        self.viewModel = viewModel
        observer = CommitDetailObserver(
            projects: projects,
            onSelectionChanged: { [weak viewModel, weak projects] in
                guard let projects else { return }
                viewModel?.handleSelectionChanged(
                    commit: projects.currentCommit,
                    projectURL: projects.currentProject?.url,
                    file: projects.currentFile
                )
            },
            onCommitFilesChanged: { [weak viewModel, weak projects] in
                guard let projects else { return }
                viewModel?.handleCommitFilesChanged(
                    files: projects.currentCommitFiles,
                    isLoading: projects.isLoadingCommitFiles,
                    loadError: projects.currentCommitFilesLoadError
                )
            },
            onProjectDataChanged: { [weak viewModel] in
                viewModel?.handleProjectDataChanged()
            }
        )
        viewModel.handleSelectionChanged(
            commit: projects.currentCommit,
            projectURL: projects.currentProject?.url,
            file: projects.currentFile
        )
        viewModel.handleCommitFilesChanged(
            files: projects.currentCommitFiles,
            isLoading: projects.isLoadingCommitFiles,
            loadError: projects.currentCommitFilesLoadError
        )

        // 作为主内容区的一块贡献（order 大于 Commit Form，VStack 中位于表单下方）。
        contentView.addContentView(
            AnyView(
                CommitDetailView(projects: projects, viewModel: viewModel)
                    // Debug 构建下右下角叠加插件名 badge，便于识别内容区来源。
                    .debugPluginBadge(metadata.name)
            ),
            id: "\(id).content",
            order: 20
        )
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        observer?.cancel()
        observer = nil
        viewModel = nil
        kernel.resolveProvider((any ContentViewProviding).self)?
            .removeContentView(id: "\(id).content")
    }
}
