import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderGitRepositoryWatch
import ProviderProjects
import ProviderRailView
import ProviderToast
import ProviderWorkspaceScene
import SwiftUI

// MARK: - Worktree Status SuperPlugin

/// 工作区状态插件
///
/// 在 `onBoot` 阶段解析 `RailViewProviding` 与 `ProjectProviding`，
/// 向 Rail 注入一个纵向区块（section），显示当前项目的工作区状态
/// （干净 / 未提交变更数 + 分支名）。
///
/// 遵循 Lumi 架构：Rail 支持多区块（`VStack` 组合），本插件贡献
/// 工作区状态区块，位于 commit 列表区块上方。
@MainActor
public final class WorktreeStatusPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.worktree-status", category: "WorktreeStatus")
    nonisolated public static let emoji = "🌿"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.worktree-status"
    /// 依赖项目管理服务先启动；需排在 commit 列表区块之前。
    public let order = 15
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.worktree-status",
        name: "Worktree Status",
        description: "Rail section showing the working tree status of the current project",
        category: .project,
        stage: .stable,
        policy: .required
    )

    private var sceneViewModel: WorkspaceSceneVisibilityViewModel?
    private var sceneObserver: WorktreeStatusSceneObserver?

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let rail = kernel.resolveProvider((any RailViewProviding).self) else {
            Self.logger.error("\(self.t)RailViewProviding not registered; skip rail section injection")
            return
        }
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error("\(self.t)ProjectProviding not registered; skip rail section injection")
            return
        }
        // GitRepositoryWatching 可选：插件可能未注册（例如测试环境），此时仅依赖
        // ProjectProviding.dataChanged 刷新；真实运行时由 PluginGitRepositoryWatch 提供。
        let gitWatch = kernel.resolveProvider((any GitRepositoryWatching).self)
        let toast = kernel.resolveProvider((any ToastProviding).self)

        guard let scene = kernel.resolveProvider((any WorkspaceSceneProviding).self) else {
            Self.logger.error("\(self.t)WorkspaceSceneProviding not registered; skip scene wiring")
            return
        }

        let sceneViewModel = WorkspaceSceneVisibilityViewModel(targetScene: .git)
        let section = RailSectionItem(id: "\(id).section", order: 15) {
            WorkspaceSceneVisibilityView(viewModel: sceneViewModel) {
                WorkingTreeStatusView(projects: projects, gitWatch: gitWatch, toast: toast)
            }
        }
        self.sceneViewModel = sceneViewModel
        let sceneCapability = WorktreeStatusSceneCapabilityAdapter(scene: scene)
        self.sceneObserver = WorktreeStatusSceneObserver(
            capability: sceneCapability,
            viewModel: sceneViewModel,
            onVisibilityChanged: { [weak rail] isVisible in
                guard let rail else { return }
                if isVisible {
                    rail.addSections([section])
                } else {
                    rail.removeSections(ids: [section.id])
                }
            }
        )
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        sceneObserver?.cancel()
        sceneObserver = nil
        sceneViewModel = nil
        kernel.resolveProvider((any RailViewProviding).self)?
            .removeSections(ids: ["\(id).section"])
    }
}
