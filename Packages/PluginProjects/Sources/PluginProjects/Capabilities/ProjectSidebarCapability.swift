import Foundation
import ProviderProjects

/// 项目列表侧边栏所需的最小能力。
///
/// 插件入口在装配阶段用 `ProjectProviding` 适配本协议；视图、Picker 与
/// 协调器只依赖它，不再直接持有 24 个成员的项目 Provider。
@MainActor
protocol ProjectSidebarCapability: AnyObject {
    var projects: [Project] { get }
    var currentProject: Project? { get }

    func addProject(at url: URL)
    func openProject(at url: URL)
    func setCurrentProject(id: UUID?)
    func removeProject(id: UUID)
    func pinProject(id: UUID, isPinned: Bool)
    func moveProject(id: UUID, beforeID: UUID?)
    func renameProject(id: UUID, newName: String) throws
    func notifyDataChanged()

    @discardableResult
    func addObserver(
        _ callback: @escaping (ProjectProvidingEvent) -> Void
    ) -> any ProjectProvidingObserverHandle
}

/// 将 `ProjectProviding` 收窄成侧边栏所需的能力。
@MainActor
final class ProjectSidebarCapabilityAdapter: ProjectSidebarCapability {
    private let provider: any ProjectProviding

    init(projects: any ProjectProviding) {
        self.provider = projects
    }

    var projects: [Project] { provider.projects }
    var currentProject: Project? { provider.currentProject }

    func addProject(at url: URL) { provider.addProject(at: url) }
    func openProject(at url: URL) { provider.openProject(at: url) }
    func setCurrentProject(id: UUID?) { provider.setCurrentProject(id: id) }
    func removeProject(id: UUID) { provider.removeProject(id: id) }
    func pinProject(id: UUID, isPinned: Bool) { provider.pinProject(id: id, isPinned: isPinned) }
    func moveProject(id: UUID, beforeID: UUID?) { provider.moveProject(id: id, beforeID: beforeID) }
    func renameProject(id: UUID, newName: String) throws {
        try provider.renameProject(id: id, newName: newName)
    }
    func notifyDataChanged() { provider.notifyDataChanged() }

    @discardableResult
    func addObserver(
        _ callback: @escaping (ProjectProvidingEvent) -> Void
    ) -> any ProjectProvidingObserverHandle {
        provider.addObserver(callback)
    }
}
