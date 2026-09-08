import Foundation
import KitGit
import ProviderGitRepositoryWatch
import ProviderGit
import ProviderProjects

private struct GitConflictResolverSnapshot: Sendable {
    let conflictedFiles: [String]
    let resolvedFiles: [String]
    let isOperationInProgress: Bool
    let isCherryPicking: Bool
}

/// 将项目与仓库变化映射为冲突解决 ViewModel 的刷新。
@MainActor
final class GitConflictResolverObserver {
    private let capability: any GitConflictResolverCapability
    private let git: any GitProviding
    private weak var viewModel: GitConflictResolverViewModel?
    private var projectHandle: (any ProjectProvidingObserverHandle)?
    private var repositoryHandle: (any GitRepositoryWatchingObserverHandle)?
    private var reloadGeneration = 0
    private var presentationRequested = false

    init(
        capability: any GitConflictResolverCapability,
        git: any GitProviding,
        viewModel: GitConflictResolverViewModel
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
            case .started, .stopped, .headChanged, .indexChanged, .workingTreeChanged:
                self?.reload()
            case .stashChanged, .refsChanged:
                // These events do not change the current merge conflict state.
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

    /// 外部插件请求展示时，先刷新 Git 状态，避免 ViewModel 还没来得及
    /// 看到 MERGE_HEAD 就直接被 present() 的状态保护挡住。
    func requestPresentation() {
        presentationRequested = true
        reload()
    }

    private func reload() {
        reloadGeneration += 1
        let generation = reloadGeneration
        guard let url = capability.currentProject?.url else {
            viewModel?.update(
                projectURL: nil,
                conflictedFiles: [],
                isOperationInProgress: false,
                isCherryPicking: false,
                resolvedFiles: []
            )
            return
        }

        viewModel?.beginLoading(projectURL: url)
        let git = self.git
        let snapshotTask = Task.detached(priority: .utility) {
            let conflictedFiles = git.conflictFiles(in: url)
            return GitConflictResolverSnapshot(
                conflictedFiles: conflictedFiles,
                resolvedFiles: conflictedFiles.filter {
                    !Self.containsConflictMarkers(path: $0, in: url)
                },
                isOperationInProgress: git.isMerging(in: url),
                isCherryPicking: git.cherryPickStatus(in: url).isCherryPicking
            )
        }
        Task { @MainActor [weak self] in
            let snapshot = await snapshotTask.value
            guard let self, self.reloadGeneration == generation else { return }
            let operationInProgress = snapshot.isOperationInProgress || snapshot.isCherryPicking
            self.viewModel?.update(
                projectURL: url,
                conflictedFiles: snapshot.conflictedFiles,
                isOperationInProgress: operationInProgress,
                isCherryPicking: snapshot.isCherryPicking,
                resolvedFiles: snapshot.resolvedFiles
            )
            if self.presentationRequested {
                self.presentationRequested = false
                if operationInProgress {
                    self.viewModel?.present()
                }
            }
        }
    }

    private nonisolated static func containsConflictMarkers(path: String, in repository: URL) -> Bool {
        let fileURL = repository.appendingPathComponent(path)
        guard let data = try? Data(contentsOf: fileURL),
              let contents = String(data: data, encoding: .utf8) else {
            // Binary or unreadable files cannot be classified from their contents;
            // keep them unresolved until Git reports them as staged.
            return true
        }

        return contents.split(whereSeparator: \.isNewline).contains { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            return trimmed.hasPrefix("<<<<<<<")
                || trimmed.hasPrefix("=======")
                || trimmed.hasPrefix(">>>>>>>")
        }
    }
}
