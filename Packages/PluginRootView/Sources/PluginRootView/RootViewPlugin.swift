import Combine
import Foundation
import KernelCore
import LumiLoggingKit
import os
import ProviderCloneRepository
import ProviderProjectLanguages
import ProviderProjectReadme
import ProviderProjects
import ProviderRailView
import GitOKProviderRootView
import ProviderRootView
import ProviderToolbar
import SwiftUI
import ProviderDocsView

// MARK: - RootViewPlugin

/// 根视图插件：为宿主注册的根视图提供工作区门控。
///
/// 根视图 Provider 由宿主拥有（`GitOKHostManifest.makeRootViewProvider`
/// 注册 `GitOKRootViewProvider`），本插件在 `onBoot` 中解析并接管它，
/// 不再做替换式注册——基础设施的所有权归宿主，插件只贡献行为。
///
/// 监听 `ProjectProviding` 的项目列表与当前项目：统一决定工作区是无项目、
/// 项目已从磁盘消失，还是可以挂载业务插件视图。不可用时由根布局直接替换工作区，
/// 避免业务插件先挂载并启动 Git loading。
///
/// `order = 5` 保证在所有消费 RootViewProviding 的插件之前完成门控接线。
@MainActor
public final class RootViewPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.root-view", category: "RootView")
    nonisolated public static let emoji = "🏠"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.root-view"
    /// 必须在所有消费 RootViewProviding 的插件之前启动。
    public let order = 5
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.root-view",
        name: "Root View",
        description: pluginLocalization.string("Provides workspace gating for the host root view"),
        category: .core,
        stage: .stable,
        policy: .required
    )

    /// 宿主注册的根视图 Provider；onBoot 接管，onShutdown 释放。
    public private(set) var provider: GitOKRootViewProvider?

    /// 项目监听者：装配阶段创建，卸载时取消。
    private var observer: RootViewProjectObserver?
    private var toolbarProvider: (any ToolbarProviding)?

    /// 装配阶段收窄得到的插件能力；视图与观察者只持有它们，不直接持有 Provider。
    private var projectCapability: RootViewProjectCapability?
    private var cloneCapability: RootViewCloneCapability?

    private let workspaceModel = RootWorkspaceModel()

    public init() {}

    public func onRegister(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any DocsViewProviding).self)?.addAbout(
            DocsEntry(id: id, name: metadata.name) { RootViewAboutView() }
        )
    }

    public func onUnregister(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any DocsViewProviding).self)?.removeEntries(id: id)
    }

    public func onBoot(kernel: KernelCoreContainer) throws {
        // 接管宿主注册的根视图 Provider（不做替换式注册）。
        guard let provider = kernel.resolveProvider((any RootViewProviding).self) as? GitOKRootViewProvider else {
            Self.logger.error("\(self.t)GitOKRootViewProvider not registered by host; skip workspace gating")
            return
        }
        self.provider = provider

        // 解析项目服务。
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error("\(self.t)ProjectProviding not registered; skip no-project guide")
            return
        }
        toolbarProvider = kernel.resolveProvider((any ToolbarProviding).self)

        // 装配阶段收窄 Provider：视图与观察者只依赖插件自己的窄能力。
        let projectCapability = RootViewProjectCapabilityAdapter(projects: projects)
        let cloneCapability = RootViewCloneCapabilityAdapter(
            cloneRepository: kernel.resolveProvider((any CloneRepositoryProviding).self)
        )
        self.projectCapability = projectCapability
        self.cloneCapability = cloneCapability

        provider.setWorkspaceUnavailableView(
            AnyView(
                RootWorkspaceUnavailableView(
                    model: workspaceModel,
                    projects: projectCapability,
                    cloneRepository: cloneCapability,
                    readmeProvider: { [weak kernel] in
                        kernel?.resolveProvider((any ProjectReadmeProviding).self)
                    },
                    languagesProvider: { [weak kernel] in
                        kernel?.resolveProvider((any ProjectLanguagesProviding).self)
                    }
                )
            )
        )

        // 项目列表 / 当前选择发生变化时同步更新根布局门控。
        observer = RootViewProjectObserver(
            projects: projectCapability,
            cloneRepository: cloneCapability,
            onWorkspaceChanged: { [weak self] in
                guard let self else { return }
                self.updateWorkspaceState()
            }
        )
        updateWorkspaceState()
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        observer?.cancel()
        observer = nil
        projectCapability = nil
        cloneCapability = nil
        toolbarProvider?.setHiddenCategories([], for: id)
        toolbarProvider = nil
        provider?.setWorkspaceUnavailableView(nil)
        provider = nil
        workspaceModel.reset()
    }

    private func updateWorkspaceState() {
        guard let projects = projectCapability, let cloneRepository = cloneCapability else { return }
        let state: RootWorkspaceState
        if let project = projects.currentProject {
            if let cloneTask = cloneRepository.task(for: project.url) {
                switch cloneTask.status {
                case .queued, .cloning, .cancelling:
                    state = .cloning
                case .failed, .cancelled:
                    state = .cloneFailed
                case .completed:
                    state = repositoryWorkspaceState(for: project)
                }
            } else if FileManager.default.fileExists(atPath: project.url.path) {
                state = repositoryWorkspaceState(for: project)
            } else {
                state = .projectMissing(path: project.url.path)
            }
        } else {
            state = .noProject
        }
        workspaceModel.update(state: state, project: projects.currentProject)
        provider?.setWorkspaceState(state)
        toolbarProvider?.setHiddenCategories(
            state == .cloning || state == .cloneFailed ? [.project] : [],
            for: id
        )
    }

    private func repositoryWorkspaceState(for project: Project) -> RootWorkspaceState {
        guard FileManager.default.fileExists(atPath: project.url.path) else {
            return .projectMissing(path: project.url.path)
        }

        // 目录存在但缺少 `.git`（目录或 worktree 指针文件）→ 不是 Git 项目。
        return FileManager.default.fileExists(
            atPath: project.url.appendingPathComponent(".git").path
        ) ? .ready : .notGitRepository(path: project.url.path)
    }
}

// MARK: - GitOKRootViewProvider

/// `RootViewProviding` 的 GitOK 实现：直接继承 GitOK 的 `DefaultRootViewProvider`
/// （共享 `DefaultRootViewProviding` 的子类），所有 setter / overlay /
/// trailing pane / rail visibility / content footer height / 工作区门控
/// 语义与默认实现一致。
@MainActor
public final class GitOKRootViewProvider: GitOKProviderRootView.DefaultRootViewProvider {}
