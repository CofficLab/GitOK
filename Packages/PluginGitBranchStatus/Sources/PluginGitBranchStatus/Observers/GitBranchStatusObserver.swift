import KitGit
import ProviderGitRepositoryWatch
import ProviderProjects

/// 将项目选择与仓库 HEAD/refs 变化映射为当前分支 ViewModel 的刷新。
@MainActor
final class GitBranchStatusObserver {
    private let capability: any GitBranchStatusCapability
    private weak var viewModel: GitBranchStatusViewModel?
    private var projectHandle: (any ProjectProvidingObserverHandle)?
    private var repositoryHandle: (any GitRepositoryWatchingObserverHandle)?
    private var reloadGeneration = 0

    init(
        capability: any GitBranchStatusCapability,
        viewModel: GitBranchStatusViewModel
    ) {
        self.capability = capability
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
        projectHandle?.cancel()
        projectHandle = nil
        repositoryHandle?.cancel()
        repositoryHandle = nil
        viewModel = nil
    }

    private func reload() {
        reloadGeneration += 1
        let generation = reloadGeneration
        guard let url = capability.currentProject?.url else {
            viewModel?.update(projectURL: nil, branch: nil)
            return
        }

        viewModel?.beginLoading(projectURL: url)
        Task.detached(priority: .utility) { [weak self] in
            let branch = GitRefReader.currentBranch(in: url)
            await MainActor.run {
                guard let self, self.reloadGeneration == generation else { return }
                self.viewModel?.update(projectURL: url, branch: branch)
            }
        }
    }
}
