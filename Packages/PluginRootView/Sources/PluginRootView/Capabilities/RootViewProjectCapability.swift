import Foundation
import ProviderProjects

/// 根视图插件读取项目列表与当前项目的最小能力。
///
/// 插件入口用本能力把 `ProjectProviding` 收窄；Observer 与 View 只依赖此协议，
/// 避免项目 Provider 穿透到视图层。
@MainActor
protocol RootViewProjectCapability: AnyObject {
    var currentProject: Project? { get }

    @discardableResult
    func addObserver(
        _ callback: @escaping (ProjectProvidingEvent) -> Void
    ) -> any ProjectProvidingObserverHandle

    func addProject(at url: URL)
    func openProject(at url: URL)
    func removeProject(id: UUID)
}

/// 将 `ProjectProviding` 收窄成根视图所需的能力。
@MainActor
final class RootViewProjectCapabilityAdapter: RootViewProjectCapability {
    private let projects: any ProjectProviding

    init(projects: any ProjectProviding) {
        self.projects = projects
    }

    var currentProject: Project? { projects.currentProject }

    @discardableResult
    func addObserver(
        _ callback: @escaping (ProjectProvidingEvent) -> Void
    ) -> any ProjectProvidingObserverHandle {
        projects.addObserver(callback)
    }

    func addProject(at url: URL) { projects.addProject(at: url) }
    func openProject(at url: URL) { projects.openProject(at: url) }
    func removeProject(id: UUID) { projects.removeProject(id: id) }
}