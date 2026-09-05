import Foundation
import KitGit
import ProviderProjects

/// Git Diff 插件读取项目选择状态的最小能力。
@MainActor
protocol GitDiffProjectCapability: AnyObject {
    var currentCommit: GitCommit? { get }
    var currentProjectURL: URL? { get }
    var currentFile: String? { get }

    @discardableResult
    func addObserver(
        _ callback: @escaping (ProjectProvidingEvent) -> Void
    ) -> any ProjectProvidingObserverHandle
}

/// 将 ProjectProviding 收窄成 Git Diff 所需的能力。
@MainActor
final class GitDiffProjectCapabilityAdapter: GitDiffProjectCapability {
    private let projects: any ProjectProviding

    init(projects: any ProjectProviding) {
        self.projects = projects
    }

    var currentCommit: GitCommit? { projects.currentCommit }
    var currentProjectURL: URL? { projects.currentProject?.url }
    var currentFile: String? { projects.currentFile }

    @discardableResult
    func addObserver(
        _ callback: @escaping (ProjectProvidingEvent) -> Void
    ) -> any ProjectProvidingObserverHandle {
        projects.addObserver(callback)
    }
}
