import Foundation
import KitGit
import ProviderGitRepositoryWatch
import ProviderGit
import ProviderProjects

private struct GitConflictResolverSnapshot: Sendable {
    let conflictedFiles: [String]
    let resolvedFiles: [String]
    let autoResolvableFiles: [String]
    let bothDeletedFiles: [String]
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
    private var snapshotTask: Task<Void, Never>?
    private var reloadRequestedWhileReading = false

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
        snapshotTask?.cancel()
        snapshotTask = nil
        reloadRequestedWhileReading = false
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
        if snapshotTask != nil {
            // A working-tree event does not need another concurrent status
            // walk. Keep the newest generation and perform one follow-up read
            // after the current snapshot has completed.
            reloadRequestedWhileReading = true
            return
        }
        guard let url = capability.currentProject?.url else {
            viewModel?.update(
                projectURL: nil,
                conflictedFiles: [],
                isOperationInProgress: false,
                isCherryPicking: false,
                resolvedFiles: [],
                autoResolvableFiles: [],
                bothDeletedFiles: []
            )
            return
        }

        viewModel?.beginLoading(projectURL: url)
        let git = self.git
        snapshotTask = Task { @MainActor [weak self] in
            let snapshot = await Task.detached(priority: .utility) {
                let entries = git.conflictEntries(in: url)
                // Index shape decides what still needs a decision: both-deleted
                // entries resolve by dropping them and one-sided additions keep
                // the surviving side. A one-sided entry whose file is not on
                // disk cannot be staged safely, so it stays in the manual list.
                let autoResolvable = entries.filter { entry in
                    switch entry.kind {
                    case .bothDeleted:
                        return true
                    case .oneSided:
                        return FileManager.default.fileExists(
                            atPath: url.appendingPathComponent(entry.path).path
                        )
                    case .content, .deleteModify, .unknown:
                        return false
                    }
                }
                let autoPaths = Set(autoResolvable.map(\.path))
                // Only two-sided entries are worth reading for conflict markers.
                let contentCandidates = entries.filter {
                    !autoPaths.contains($0.path) && $0.kind != .deleteModify
                }
                return GitConflictResolverSnapshot(
                    conflictedFiles: entries.map(\.path),
                    resolvedFiles: contentCandidates
                        .filter { !Self.containsConflictMarkers(path: $0.path, in: url) }
                        .map(\.path),
                    autoResolvableFiles: autoResolvable.map(\.path),
                    bothDeletedFiles: autoResolvable.filter { $0.kind == .bothDeleted }.map(\.path),
                    isOperationInProgress: git.isMerging(in: url),
                    isCherryPicking: git.cherryPickStatus(in: url).isCherryPicking
                )
            }.value

            guard let self else { return }
            let shouldApply = self.reloadGeneration == generation
            if shouldApply {
                let operationInProgress = snapshot.isOperationInProgress || snapshot.isCherryPicking
                self.viewModel?.update(
                    projectURL: url,
                    conflictedFiles: snapshot.conflictedFiles,
                    isOperationInProgress: operationInProgress,
                    isCherryPicking: snapshot.isCherryPicking,
                    resolvedFiles: snapshot.resolvedFiles,
                    autoResolvableFiles: snapshot.autoResolvableFiles,
                    bothDeletedFiles: snapshot.bothDeletedFiles
                )
                if self.presentationRequested {
                    self.presentationRequested = false
                    if operationInProgress {
                        self.viewModel?.present()
                    }
                }
            }

            self.snapshotTask = nil
            if self.reloadRequestedWhileReading {
                self.reloadRequestedWhileReading = false
                self.reload()
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
