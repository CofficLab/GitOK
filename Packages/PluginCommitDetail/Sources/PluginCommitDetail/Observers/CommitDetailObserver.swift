import Foundation
import KitGit
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
    private var projectsHandle: (any ProjectProvidingObserverHandle)?
    private var gitWatchHandle: (any GitRepositoryWatchingObserverHandle)?

    init(
        projects: any ProjectProviding,
        gitWatch: (any GitRepositoryWatching)?,
        viewModel: CommitDetailViewModel
    ) {
        self.viewModel = viewModel

        projectsHandle = projects.addObserver { [weak self, weak projects] event in
            guard let self, let projects else { return }
            self.handle(event, projects: projects)
        }

        // Observer 持有初始快照的同步责任，插件定义只负责装配依赖。
        syncSelection(from: projects)
        syncCommitFiles(from: projects)

        // 监听 GitRepositoryWatching 事件，感知工作区文件变化。
        // 当外部修改工作区（如其他编辑器修改文件、Finder 操作文件）时，
        // FSEventStream 监听到变化并广播 .workingTreeChanged，
        // 本 Observer 接收并触发工作区变动列表刷新。
        gitWatchHandle = gitWatch?.addObserver { [weak self] event in
            guard let self else { return }
            switch event {
            case .workingTreeChanged:
                self.viewModel.handleProjectDataChanged()
            default:
                break
            }
        }
    }

    private func handle(_ event: ProjectProvidingEvent, projects: any ProjectProviding) {
        switch event {
        case .commitSelectionChanged:
            syncSelection(from: projects)
            syncCommitFiles(from: projects)
        case .currentFileChanged:
            syncSelection(from: projects)
        case .selectionChanged:
            // 项目切换时同步完整快照，尤其是没有 commit 选择时的项目路径。
            syncSelection(from: projects)
            syncCommitFiles(from: projects)
            viewModel.handleProjectDataChanged()
        case .dataChanged:
            viewModel.handleProjectDataChanged()
        default:
            break
        }
    }

    private func syncSelection(from projects: any ProjectProviding) {
        viewModel.handleSelectionChanged(
            commit: projects.currentCommit,
            projectURL: projects.currentProject?.url,
            file: projects.currentFile
        )
    }

    private func syncCommitFiles(from projects: any ProjectProviding) {
        viewModel.handleCommitFilesChanged(
            files: projects.currentCommitFiles,
            isLoading: projects.isLoadingCommitFiles,
            loadError: projects.currentCommitFilesLoadError
        )
    }

    /// 取消全部订阅；插件卸载后不再有任何回调。
    func cancel() {
        projectsHandle?.cancel()
        projectsHandle = nil
        gitWatchHandle?.cancel()
        gitWatchHandle = nil
    }
}
