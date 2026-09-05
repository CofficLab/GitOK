import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderGitRepositoryWatch
import ProviderProjects
import ProviderRailView
import ProviderWorkspaceScene
import SwiftUI

// MARK: - Commit List SuperPlugin

/// Commit 列表插件
///
/// 在 `onBoot` 阶段解析 `RailViewProviding` 与 `ProjectProviding`，
/// 向 Rail 注入一个纵向区块（section），展示当前打开项目的 commit 列表。
///
/// 选中 commit 的状态由 `ProjectProviding` 统一维护：行点击写入
/// `ProjectProviding.selectCommit`，主内容区（PluginCommitDetail）与 diff
/// 视图（PluginGitDiff）据此展示。
///
/// 遵循 Lumi 架构：Rail 支持多区块（`VStack` 组合），本插件贡献
/// commit 列表区块；工作区状态等其它区块由各自插件贡献。根布局的
/// `setRailView(rail.makeRailView())` 由 `ViewFactory` 在插件启动后
/// 统一装配，组合所有区块。
@MainActor
public final class CommitListPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.commit-list", category: "CommitList")
    nonisolated public static let emoji = "🕑"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.commit-list"
    /// 依赖项目管理服务先启动。
    public let order = 20
    public let dependencies = ["com.coffic.gitok.plugin.projects"]
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.commit-list",
        name: "Commit List",
        description: "Rail section showing the commit history of the current project",
        category: .project,
        stage: .stable,
        policy: .required
    )

    private var sceneViewModel: WorkspaceSceneVisibilityViewModel?
    private var sceneObserver: CommitListSceneObserver?

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

        // GitRepositoryWatching 可选：插件可能未注册（例如测试环境），此时仅依赖 ProjectProviding 刷新
        let gitWatch = kernel.resolveProvider((any GitRepositoryWatching).self)

        guard let scene = kernel.resolveProvider((any WorkspaceSceneProviding).self) else {
            Self.logger.error("\(self.t)WorkspaceSceneProviding not registered; skip scene wiring")
            return
        }

        let sceneViewModel = WorkspaceSceneVisibilityViewModel(targetScene: .git)
        let section = RailSectionItem(id: "\(id).section", order: 20) {
            WorkspaceSceneVisibilityView(viewModel: sceneViewModel) {
                CommitRailView(projects: projects, gitWatch: gitWatch)
            }
        }
        self.sceneViewModel = sceneViewModel
        let sceneCapability = CommitListSceneCapabilityAdapter(scene: scene)
        self.sceneObserver = CommitListSceneObserver(
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
