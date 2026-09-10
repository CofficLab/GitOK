import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderActivityHeatmap
import ProviderContentView
import ProviderGit
import ProviderGitUser
import ProviderGitRepositoryWatch
import ProviderProjects
import ProviderProjectLanguages
import ProviderSettingView
import ProviderWorkspaceScene
import SwiftUI
import ProviderDocsView

// MARK: - Worktree Clean SuperPlugin

/// 工作区干净视图插件。
///
/// 当「当前项目已打开 + 未选中 commit + 工作区无未提交变更」时，通过
/// `ContentViewProviding` 向主内容区贡献工作区概览：顶部一行是「工作区干净」
/// 提示与本地 Git 提交活跃度热力图，下面是全宽的信息区块。
///
/// 状态由插件自有 ViewModel 持有；外部事件（项目 / commit 选择、仓库与工作区
/// 数据变化）由 `WorktreeCleanObserver` 翻译进 ViewModel。其余情况渲染
/// `EmptyView` 不占用布局——工作区变更列表仍由 CommitDetail 插件展示，
/// 并与本插件的概览内容互斥。
@MainActor
public final class WorktreeCleanPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.worktree-clean", category: "WorktreeClean")
    nonisolated public static let emoji = "✅"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.worktree-clean"
    /// 依赖项目 Provider 先启动（干净视图需要读取当前项目）。
    public let order = 22
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.worktree-clean",
        name: "Worktree Clean",
        description: "Show working-tree clean state and local commit activity when there are no uncommitted changes",
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
    private var activityHeatmapObserver: WorktreeCleanActivityHeatmapObserver?
    private var activityHeatmapViewModel: WorktreeCleanActivityHeatmapViewModel?
    private var projectLanguagesObserver: WorktreeCleanProjectLanguagesObserver?
    private var projectLanguagesViewModel: WorktreeCleanProjectLanguagesViewModel?

    public init() {}

    public func onRegister(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any DocsViewProviding).self)?.addAbout(
            DocsEntry(id: id, name: metadata.name) { WorktreeCleanAboutView() }
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
        guard let git = kernel.resolveProvider((any GitProviding).self) else {
            Self.logger.error("\(self.t)GitProviding not registered; skip clean-state content")
            return
        }

        guard let scene = kernel.resolveProvider((any WorkspaceSceneProviding).self) else {
            Self.logger.error("\(self.t)WorkspaceSceneProviding not registered; skip scene wiring")
            return
        }

        // GitRepositoryWatching 可选依赖：感知外部工作区文件变化
        // （如其他编辑器把文件改干净 / 改脏后，干净视图据此刷新）。
        let gitWatch = kernel.resolveProvider((any GitRepositoryWatching).self)
        let userPresets = kernel.resolveProvider((any GitUserPresetProviding).self)
        let collaborators = kernel.resolveProvider((any CollaboratorProviding).self)

        let ensureUserPreset: ((String, String) -> Void)?
        if let userPresets {
            ensureUserPreset = { name, email in
                let alreadyExists = userPresets.loadPresets().contains {
                    $0.name == name && $0.email == email
                }
                if !alreadyExists {
                    _ = userPresets.addPreset(name: name, email: email)
                }
            }
        } else {
            ensureUserPreset = nil
        }

        // 装配阶段创建自有 ViewModel 与外部 Observer（Lumi 插件规范：
        // 插件入口是插件级外部监听的唯一持有者）。随后显式同步一次初始快照。
        let capability = WorktreeCleanProjectCapabilityAdapter(projects: projects)
        let viewModel = WorktreeCleanViewModel(git: git, ensureUserPreset: ensureUserPreset)
        self.viewModel = viewModel
        observer = WorktreeCleanObserver(
            capability: capability,
            gitWatch: gitWatch,
            userPresets: userPresets,
            collaborators: collaborators,
            onProjectChanged: { [weak viewModel, capability] in
                viewModel?.handleProjectChanged(
                    project: capability.currentProject,
                    hasSelectedCommit: capability.hasSelectedCommit
                )
            },
            onDataChanged: { [weak viewModel] in
                viewModel?.handleDataChanged()
            },
            onUserPresetsChanged: { [weak viewModel] presets in
                viewModel?.handleUserPresetsChanged(presets)
            },
            onCollaboratorsChanged: { [weak viewModel] collaborators in
                viewModel?.handleCollaboratorsChanged(collaborators)
            }
        )
        viewModel.handleProjectChanged(
            project: capability.currentProject,
            hasSelectedCommit: capability.hasSelectedCommit
        )

        let sceneViewModel = WorkspaceSceneVisibilityViewModel(targetScene: .git)
        self.sceneViewModel = sceneViewModel
        let sceneCapability = WorktreeCleanSceneCapabilityAdapter(scene: scene)
        self.sceneObserver = WorktreeCleanSceneObserver(capability: sceneCapability, viewModel: sceneViewModel)

        let activityViewModel = WorktreeCleanActivityHeatmapViewModel()
        self.activityHeatmapViewModel = activityViewModel
        if let activityProvider = kernel.resolveProvider((any ActivityHeatmapProviding).self) {
            let activityCapability = WorktreeCleanActivityHeatmapCapabilityAdapter(
                provider: activityProvider
            )
            self.activityHeatmapObserver = WorktreeCleanActivityHeatmapObserver(
                capability: activityCapability,
                projects: projects,
                viewModel: activityViewModel
            )
        }

        let projectLanguagesViewModel = WorktreeCleanProjectLanguagesViewModel()
        self.projectLanguagesViewModel = projectLanguagesViewModel
        if let projectLanguagesProvider = kernel.resolveProvider((any ProjectLanguagesProviding).self) {
            let projectLanguagesCapability = WorktreeCleanProjectLanguagesCapabilityAdapter(
                provider: projectLanguagesProvider
            )
            self.projectLanguagesObserver = WorktreeCleanProjectLanguagesObserver(
                capability: projectLanguagesCapability,
                viewModel: projectLanguagesViewModel
            )
        }

        let openUserSettings: (() -> Void)?
        if kernel.resolveProvider((any SettingViewProviding).self) != nil {
            openUserSettings = {
                NotificationCenter.default.post(
                    name: SettingViewNavigation.openSettingsNotification,
                    object: nil,
                    userInfo: [SettingViewNavigation.entryIDUserInfoKey: "userInfo"]
                )
            }
        } else {
            openUserSettings = nil
        }

        // 一个完整的工作区概览：顶部提示与热力图横向排列，信息区块在下面纵向排列。
        contentView.addContentView(
            AnyView(
                WorkspaceSceneVisibilityView(viewModel: sceneViewModel) {
                    WorktreeCleanView(
                        viewModel: viewModel,
                        activityHeatmapViewModel: activityViewModel,
                        projectLanguagesViewModel: projectLanguagesViewModel,
                        git: git,
                        openUserSettings: openUserSettings
                    )
                }
                    // Debug 构建下左下角叠加插件名 badge，便于识别内容区来源。
                    .debugPluginBadge(metadata.name)
            ),
            id: "\(id).content",
            order: 20
        )
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        activityHeatmapObserver?.cancel()
        activityHeatmapObserver = nil
        activityHeatmapViewModel = nil
        projectLanguagesObserver?.cancel()
        projectLanguagesObserver = nil
        projectLanguagesViewModel = nil
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
