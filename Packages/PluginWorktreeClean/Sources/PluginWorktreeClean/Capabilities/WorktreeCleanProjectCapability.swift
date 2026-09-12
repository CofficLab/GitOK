import Foundation
import ProviderProjects

/// Worktree Clean 插件读取项目/commit 选择状态的最小能力。
@MainActor
protocol WorktreeCleanProjectCapability: AnyObject {
    var currentProject: Project? { get }
    var hasSelectedCommit: Bool { get }

    @discardableResult
    func addObserver(
        _ callback: @escaping (ProjectProvidingEvent) -> Void
    ) -> any ProjectProvidingObserverHandle
}

/// 将 ProjectProviding 收窄成 Worktree Clean 所需的能力。
@MainActor
final class WorktreeCleanProjectCapabilityAdapter: WorktreeCleanProjectCapability {
    private let projects: any ProjectProviding

    init(projects: any ProjectProviding) {
        self.projects = projects
    }

    var currentProject: Project? { projects.currentProject }
    var hasSelectedCommit: Bool { projects.currentCommit != nil }

    @discardableResult
    func addObserver(
        _ callback: @escaping (ProjectProvidingEvent) -> Void
    ) -> any ProjectProvidingObserverHandle {
        projects.addObserver(callback)
    }
}
