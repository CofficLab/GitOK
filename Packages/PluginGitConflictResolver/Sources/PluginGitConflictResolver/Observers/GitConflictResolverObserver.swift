import KitGit
import ProviderGitRepositoryWatch
import ProviderProjects

private struct GitConflictResolverSnapshot: Sendable {
    let conflictedFiles: [String]
    let isOperationInProgress: Bool
    let isCherryPicking: Bool
}

/// 将项目与仓库变化映射为冲突解决 ViewModel 的刷新。
@MainActor
final class GitConflictResolverObserver {
    private let capability: any GitConflictResolverCapability
    private weak var viewModel: GitConflictResolverViewModel?
    private var projectHandle: (any ProjectProvidingObserverHandle)?
    private var repositoryHandle: (any GitRepositoryWatchingObserverHandle)?
    private var reloadGeneration = 0

    init(
        capability: any GitConflictResolverCapability,
        viewModel: GitConflictResolverViewModel
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
        repositoryHandle = capability.addRepositoryObserver { [weak self] _ in
            self?.reload()
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
            viewModel?.update(
                projectURL: nil,
                conflictedFiles: [],
                isOperationInProgress: false,
                isCherryPicking: false
            )
            return
        }

        viewModel?.beginLoading(projectURL: url)
        let snapshotTask = Task.detached(priority: .utility) {
            GitConflictResolverSnapshot(
                conflictedFiles: GitMergeOperation.conflictFiles(in: url),
                isOperationInProgress: GitMergeOperation.isMerging(in: url),
                isCherryPicking: GitCherryPickOperation.status(in: url).isCherryPicking
            )
        }
        Task { @MainActor [weak self] in
            let snapshot = await snapshotTask.value
            guard let self, self.reloadGeneration == generation else { return }
            self.viewModel?.update(
                projectURL: url,
                conflictedFiles: snapshot.conflictedFiles,
                isOperationInProgress: snapshot.isOperationInProgress || snapshot.isCherryPicking,
                isCherryPicking: snapshot.isCherryPicking
            )
        }
    }
}
