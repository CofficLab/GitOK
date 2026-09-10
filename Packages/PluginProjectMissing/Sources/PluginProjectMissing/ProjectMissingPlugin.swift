import Foundation
import KernelCore
import KitSuperLog
import LumiUI
import os
import ProviderContentView
import ProviderProjects
import ProviderWorkspaceScene
import SwiftUI
import ProviderDocsView

// MARK: - Project Missing SuperPlugin

/// 项目缺失提示插件。
///
/// 当「当前项目已打开 + 项目目录在磁盘上不存在」时，通过 `ContentViewProviding`
/// 向主内容区贡献友好提示视图，告知用户项目已丢失。其余情况渲染 `EmptyView`
/// 不占用布局——与其他内容插件互斥。
@MainActor
public final class ProjectMissingPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.project-missing", category: "ProjectMissing")
    nonisolated public static let emoji = "❓"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.project-missing"
    /// 依赖项目 Provider 先启动（缺失视图需要读取当前项目）。
    public let order = 23
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.project-missing",
        name: "Project Missing",
        description: "Show a friendly notice when the current project directory no longer exists on disk",
        category: .project,
        stage: .stable,
        policy: .required
    )

    /// 插件自有 ViewModel：由外部 Observer 驱动，视图只绑定它。
    private var viewModel: ProjectMissingViewModel?
    /// 插件级外部 Observer：装配阶段创建并持有，卸载时取消。
    private var observer: ProjectMissingObserver?
    private var sceneViewModel: WorkspaceSceneVisibilityViewModel?
    private var sceneObserver: ProjectMissingSceneObserver?
    private var projects: (any ProjectProviding)?

    public init() {}

    public func onRegister(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any DocsViewProviding).self)?.addAbout(
            DocsEntry(id: id, name: metadata.name) { ProjectMissingAboutView() }
        )
    }

    public func onUnregister(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any DocsViewProviding).self)?.removeEntries(id: id)
    }

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let contentView = kernel.resolveProvider((any ContentViewProviding).self) else {
            Self.logger.error("\(self.t)ContentViewProviding not registered; skip content injection")
            return
        }
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error("\(self.t)ProjectProviding not registered; skip content injection")
            return
        }
        self.projects = projects

        guard let scene = kernel.resolveProvider((any WorkspaceSceneProviding).self) else {
            Self.logger.error("\(self.t)WorkspaceSceneProviding not registered; skip scene wiring")
            return
        }

        // 装配阶段创建自有 ViewModel 与外部 Observer（Lumi 插件规范：
        // 插件入口是插件级外部监听的唯一持有者）。
        let capability = ProjectMissingProjectCapabilityAdapter(projects: projects)
        let viewModel = ProjectMissingViewModel()
        self.viewModel = viewModel
        observer = ProjectMissingObserver(
            capability: capability,
            viewModel: viewModel
        )

        let sceneViewModel = WorkspaceSceneVisibilityViewModel(targetScene: .git)
        self.sceneViewModel = sceneViewModel
        let sceneCapability = ProjectMissingSceneCapabilityAdapter(scene: scene)
        self.sceneObserver = ProjectMissingSceneObserver(capability: sceneCapability, viewModel: sceneViewModel)

        // 移除项目的回调
        let removeProject: (() -> Void)? = { [weak self, weak projects] in
            guard let self, let projects, let project = self.viewModel?.project else { return }
            projects.removeProject(id: project.id)
        }

        // 作为主内容区的一块贡献（order 大于 WorktreeClean，VStack 中位于干净视图下方）。
        // 但两个视图互斥：WorktreeClean 在 isClean 时显示，本插件在 isMissing 时显示。
        contentView.addContentView(
            AnyView(
                WorkspaceSceneVisibilityView(viewModel: sceneViewModel) {
                    ProjectMissingView(
                        viewModel: viewModel,
                        onRemoveProject: removeProject
                    )
                }
                    // Debug 构建下左下角叠加插件名 badge，便于识别内容区来源。
                    .debugPluginBadge(metadata.name)
            ),
            id: "\(id).content",
            order: 23
        )
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        sceneObserver?.cancel()
        sceneObserver = nil
        sceneViewModel = nil
        observer?.cancel()
        observer = nil
        viewModel = nil
        projects = nil
        kernel.resolveProvider((any ContentViewProviding).self)?
            .removeContentView(id: "\(id).content")
    }
}
