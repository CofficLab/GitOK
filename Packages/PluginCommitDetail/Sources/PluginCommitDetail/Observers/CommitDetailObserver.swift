import Foundation
import KitGit
import ProviderGit
import ProviderGitRepositoryWatch
import ProviderProjects

/// 提交详情插件的插件级外部观察者。
///
/// 遵循 Lumi 插件规范（`docs/plans/2026-09-03-plugin-observer-only.md`）：
/// 插件入口在装配阶段创建本 Observer 并持有，直到 `onShutdown` 取消。
/// Observer 是外部 providing 到插件内部 ViewModel 的唯一桥梁；View 与
/// ViewModel 本身不注册任何插件级外部监听。
///
/// 外部输入均为类型化通道，全部来自 `ProjectProviding` 与 `GitRepositoryWatching`：
/// - `.commitSelectionChanged` / `.currentFileChanged`：当前 commit / 文件
///   （含 commit 变动文件加载状态）变化；
/// - `.dataChanged`：提交 / 推送 / 分支切换后仓库数据变化（工作区变动列表
///   据此重载）；
/// - `.selectionChanged`：切换 / 打开 / 关闭当前项目（即使未选中 commit，
///   工作区与仓库信息视图也要据此重载，避免残留旧项目数据）。
/// - `.workingTreeChanged`：工作区文件变化（外部编辑 / 新增 / 删除文件），
///   工作区变动列表据此重载。
@MainActor
final class CommitDetailObserver {
    private let viewModel: CommitDetailViewModel
    private let git: (any GitProviding)?
    private var projectsHandle: (any ProjectProvidingObserverHandle)?
    private var gitWatchHandle: (any GitRepositoryWatchingObserverHandle)?
    private var worktreeOwnerHandle: (any WorktreeContentOwnerObserverHandle)?

    init(
        capability: any CommitDetailProjectCapability,
        gitWatch: (any GitRepositoryWatching)?,
        git: (any GitProviding)? = nil,
        viewModel: CommitDetailViewModel
    ) {
        self.viewModel = viewModel
        self.git = git

        projectsHandle = capability.addObserver { [weak self] event in
            self?.handle(event, capability: capability)
        }

        syncSelection(from: capability)
        syncCommitFiles(from: capability)

        // 工作区内容归属由 Provider 统一广播：变更列表与干净概览共用同一份判定，
        // 避免两个内容块同时「不占布局」让主内容区塌陷。
        worktreeOwnerHandle = git?.addWorktreeContentOwnerObserver { [weak self] url, owner in
            guard let self else { return }
            self.viewModel.handleWorktreeOwnerChanged(owner)
        }
        syncWorktreeOwner(from: capability)

        gitWatchHandle = gitWatch?.addObserver { [weak self] event in
            guard let self else { return }
            switch event {
            case .headChanged, .indexChanged, .refsChanged, .workingTreeChanged:
                // 外部提交通常只改变 .git/HEAD 和 index，工作区文件本身
                // 不一定发生变化，因此不能只依赖 workingTreeChanged。
                self.viewModel.handleProjectDataChanged()
            default:
                break
            }
        }
    }

    @available(*, deprecated, message: "Inject CommitDetailProjectCapability from CommitDetailPlugin")
    convenience init(
        projects: any ProjectProviding,
        gitWatch: (any GitRepositoryWatching)?,
        viewModel: CommitDetailViewModel
    ) {
        self.init(
            capability: CommitDetailProjectCapabilityAdapter(projects: projects),
            gitWatch: gitWatch,
            viewModel: viewModel
        )
    }

    private func handle(_ event: ProjectProvidingEvent, capability: any CommitDetailProjectCapability) {
        switch event {
        case .commitSelectionChanged:
            syncSelection(from: capability)
            syncCommitFiles(from: capability)
        case .currentFileChanged:
            syncSelection(from: capability)
        case .selectionChanged:
            // 项目切换时同步完整快照，尤其是没有 commit 选择时的项目路径。
            syncSelection(from: capability)
            syncCommitFiles(from: capability)
            syncWorktreeOwner(from: capability)
            viewModel.handleProjectDataChanged()
        case .dataChanged:
            viewModel.handleProjectDataChanged()
        default:
            break
        }
    }

    private func syncSelection(from capability: any CommitDetailProjectCapability) {
        viewModel.handleSelectionChanged(
            commit: capability.currentCommit,
            projectURL: capability.currentProjectURL,
            file: capability.currentFile
        )
    }

    private func syncCommitFiles(from capability: any CommitDetailProjectCapability) {
        viewModel.handleCommitFilesChanged(
            files: capability.currentCommitFiles,
            isLoading: capability.isLoadingCommitFiles,
            loadError: capability.currentCommitFilesLoadError,
            commitHash: capability.currentCommit?.hash
        )
    }

    /// 同步当前项目的工作区内容归属（切换项目时读取该仓库最新结论）。
    private func syncWorktreeOwner(from capability: any CommitDetailProjectCapability) {
        guard let git, let url = capability.currentProjectURL else { return }
        viewModel.handleWorktreeOwnerChanged(git.worktreeContentOwner(for: url))
    }

    /// 取消全部订阅；插件卸载后不再有任何回调。
    func cancel() {
        projectsHandle?.cancel()
        projectsHandle = nil
        gitWatchHandle?.cancel()
        gitWatchHandle = nil
        worktreeOwnerHandle?.cancel()
        worktreeOwnerHandle = nil
    }
}
