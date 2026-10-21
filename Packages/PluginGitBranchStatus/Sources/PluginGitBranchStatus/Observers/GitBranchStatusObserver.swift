import Foundation
import KitGit
import ProviderGit
import ProviderGitRepositoryWatch
import ProviderProjects

/// 将项目选择与仓库 HEAD/refs 变化映射为当前分支 ViewModel 的刷新。
@MainActor
final class GitBranchStatusObserver {
    private let capability: any GitBranchStatusCapability
    private let git: any GitProviding
    private weak var viewModel: GitBranchStatusViewModel?
    private var projectHandle: (any ProjectProvidingObserverHandle)?
    private var repositoryHandle: (any GitRepositoryWatchingObserverHandle)?
    private var reloadGeneration = 0

    /// 当前在途的分支读取。
    ///
    /// 切换项目时 `.selectionChanged` 与仓库监听的 `.started` 会连续到达，
    /// 因此这里必须持有并在下次 reload 前终止上一次读取；否则失效的 git
    /// 读取会继续占用线程池工作线程，最终让 loading 状态永远无法结束。
    private var branchTask: Task<String?, Never>?
    private var branchCancellation: GitProcessCancellation?

    init(
        capability: any GitBranchStatusCapability,
        git: any GitProviding,
        viewModel: GitBranchStatusViewModel
    ) {
        self.capability = capability
        self.git = git
        self.viewModel = viewModel
        projectHandle = capability.addProjectObserver { [weak self] event in
            switch event {
            case .selectionChanged, .dataChanged:
                self?.reload()
            default:
                break
            }
        }
        repositoryHandle = capability.addRepositoryObserver { [weak self] event in
            switch event {
            case .started, .stopped, .headChanged, .refsChanged:
                self?.reload()
            case .indexChanged, .stashChanged, .workingTreeChanged:
                break
            }
        }
        reload()
    }

    func cancel() {
        reloadGeneration += 1
        cancelBranchRead()
        projectHandle?.cancel()
        projectHandle = nil
        repositoryHandle?.cancel()
        repositoryHandle = nil
        viewModel = nil
    }

    private func reload() {
        reloadGeneration += 1
        let generation = reloadGeneration

        // 先终止上一次读取：新事件已经到达，旧结果对 UI 已无意义。
        cancelBranchRead()

        guard let url = capability.currentProject?.url,
              FileManager.default.fileExists(atPath: url.path) else {
            viewModel?.update(projectURL: nil, branch: nil)
            return
        }

        viewModel?.beginLoading(projectURL: url)
        let git = self.git
        let cancellation = GitProcessCancellation()
        let task = Task.detached(priority: .utility) {
            git.currentBranch(in: url, cancellation: cancellation)
        }
        branchCancellation = cancellation
        branchTask = task
        Task { @MainActor [weak self] in
            let branch = await task.value
            guard let self, self.reloadGeneration == generation else { return }
            self.branchTask = nil
            self.branchCancellation = nil
            self.viewModel?.update(projectURL: url, branch: branch)
        }
    }

    /// 终止在途的分支读取并清除引用。
    private func cancelBranchRead() {
        branchTask?.cancel()
        branchTask = nil
        branchCancellation?.cancel()
        branchCancellation = nil
    }
}
