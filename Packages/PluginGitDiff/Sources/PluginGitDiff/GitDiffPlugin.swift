import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderProjects
import ProviderRootView
import SwiftUI

/// Git Diff 插件
///
/// 在 `onBoot` 阶段解析 `RootViewProviding` 与 `ProjectProviding`，
/// 通过 RootView 的右侧面板槽位（trailing pane）注册 diff 视图：
/// 装配阶段创建自有 `GitDiffViewModel` 与插件级 `GitDiffObserver`；
/// 当「当前文件」（+ 可选 commit + 项目路径）变化时，Observer 把外部
/// 事件翻译进 ViewModel，驱动本视图异步加载该文件的 unified diff——
/// 有 commit 时加载该文件在该 commit 中的 diff，无 commit（工作区变动）时
/// 加载该文件相对工作区的 diff；用旧版同款渲染组件 `MagicDiffView` 展示
/// （git 原生 diff 文本）。
///
/// 遵循 Lumi 架构：RootView 通过 `setTrailingPane(_:)` 提供右侧面板槽位，
/// 插件在装配阶段注入自己的内容视图；插件入口是插件级外部监听的唯一
/// 持有者（`Observers` 目录）。
@MainActor
public final class GitDiffPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.git-diff", category: "GitDiff")
    nonisolated public static let emoji = "⇄"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.git-diff"
    /// 在 commit-detail 之后启动（文件选择由 commit-detail 的文件列表写入 Provider）。
    public let order = 30
    public let dependencies = ["com.coffic.gitok.plugin.commit-detail"]
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.git-diff",
        name: "Git Diff",
        description: "Trailing pane showing the diff of the selected file in the selected commit",
        category: .project,
        stage: .stable,
        policy: .required
    )

    /// 插件自有 ViewModel：由外部 Observer 驱动，视图只绑定它。
    private var viewModel: GitDiffViewModel?
    /// 插件级外部 Observer：装配阶段创建并持有，卸载时取消。
    private var observer: GitDiffObserver?

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let rootView = kernel.resolveProvider((any RootViewProviding).self) else {
            Self.logger.error("\(self.t)RootViewProviding not registered; skip trailing pane injection")
            return
        }
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error("\(self.t)ProjectProviding not registered; skip trailing pane injection")
            return
        }

        // 装配阶段创建自有 ViewModel 与外部 Observer（Lumi 插件规范：
        // 插件入口是插件级外部监听的唯一持有者）。随后显式同步一次初始快照，
        // 避免注册时机导致 UI 永久使用默认值。
        let capability = GitDiffProjectCapabilityAdapter(projects: projects)
        let viewModel = GitDiffViewModel()
        self.viewModel = viewModel

        let pane = RootTrailingPane(
            id: "\(id).trailing",
            minWidth: 320,
            idealWidth: 420,
            maxWidth: .infinity,
            // 初始可见性与当前是否有选中文件一致；无选中文件时右侧面板隐藏，
            // 避免空占位（下方 observer 会在文件选择变化时同步显隐）。
            isVisible: capability.currentFile != nil,
            content: AnyView(
                GitDiffPaneView(viewModel: viewModel)
                    // Debug 构建下左下角叠加插件名 badge，便于识别视图来源。
                    .debugPluginBadge(metadata.name)
            )
        )
        rootView.setTrailingPane(pane)

        // 选中文件是 diff 面板的唯一驱动：选中文件时显示面板，
        // 清除文件选择（切换 commit / 清空 commit 选择）时隐藏面板，
        // 不再由面板自身渲染空占位。
        let syncPaneVisibility = { [weak pane] in
            pane?.isVisible = capability.currentFile != nil
        }

        observer = GitDiffObserver(
            capability: capability,
            onSelectionChanged: { [weak viewModel, capability] in
                viewModel?.handleSelectionChanged(
                    commit: capability.currentCommit,
                    projectURL: capability.currentProjectURL,
                    file: capability.currentFile
                )
                syncPaneVisibility()
            },
            onProjectDataChanged: { [weak viewModel] in
                viewModel?.handleProjectDataChanged()
            }
        )
        viewModel.handleSelectionChanged(
            commit: capability.currentCommit,
            projectURL: capability.currentProjectURL,
            file: capability.currentFile
        )
        syncPaneVisibility()
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        observer?.cancel()
        observer = nil
        viewModel = nil
        kernel.resolveProvider((any RootViewProviding).self)?.setTrailingPane(nil)
    }
}
