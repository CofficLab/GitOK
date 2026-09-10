import Foundation
import ProviderProjects

/// 项目能力适配器：把 `ProjectProviding` 转成本插件需要的最小接口。
@MainActor
protocol ProjectMissingProjectCapability {
    var currentProject: Project? { get }
    func addProjectObserver(_ callback: @escaping (ProjectProvidingEvent) -> Void) -> any ProjectProvidingObserverHandle
}

/// `ProjectProviding` → `ProjectMissingProjectCapability` 适配器。
@MainActor
final class ProjectMissingProjectCapabilityAdapter: ProjectMissingProjectCapability {
    private let projects: any ProjectProviding

    init(projects: any ProjectProviding) {
        self.projects = projects
    }

    var currentProject: Project? {
        projects.currentProject
    }

    func addProjectObserver(_ callback: @escaping (ProjectProvidingEvent) -> Void) -> any ProjectProvidingObserverHandle {
        projects.addObserver(callback)
    }
}
