import Foundation
import KitGit
import ProviderProjects

/// Commit Detail 插件读取项目选择并发出用户意图的最小能力。
@MainActor
protocol CommitDetailProjectCapability: AnyObject {
    var currentCommit: GitCommit? { get }
    var currentProjectURL: URL? { get }
    var currentFile: String? { get }
    var currentCommitFiles: [GitFileChange]? { get }
    var isLoadingCommitFiles: Bool { get }
    var currentCommitFilesLoadError: String? { get }

    @discardableResult
    func addObserver(
        _ callback: @escaping (ProjectProvidingEvent) -> Void
    ) -> any ProjectProvidingObserverHandle

    func selectFile(_ path: String?)
    func notifyDataChanged()
}

/// 将 ProjectProviding 收窄成 Commit Detail 所需的能力。
@MainActor
final class CommitDetailProjectCapabilityAdapter: CommitDetailProjectCapability {
    private let projects: any ProjectProviding

    init(projects: any ProjectProviding) {
        self.projects = projects
    }

    var currentCommit: GitCommit? { projects.currentCommit }
    var currentProjectURL: URL? { projects.currentProject?.url }
    var currentFile: String? { projects.currentFile }
    var currentCommitFiles: [GitFileChange]? { projects.currentCommitFiles }
    var isLoadingCommitFiles: Bool { projects.isLoadingCommitFiles }
    var currentCommitFilesLoadError: String? { projects.currentCommitFilesLoadError }

    @discardableResult
    func addObserver(
        _ callback: @escaping (ProjectProvidingEvent) -> Void
    ) -> any ProjectProvidingObserverHandle {
        projects.addObserver(callback)
    }

    func selectFile(_ path: String?) {
        projects.selectFile(path)
    }

    func notifyDataChanged() {
        projects.notifyDataChanged()
    }
}
