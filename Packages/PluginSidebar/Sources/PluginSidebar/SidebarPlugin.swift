import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderProjects
import ProviderSettingView
import ProviderSidebar

// MARK: - Sidebar SuperPlugin

/// 侧边栏插件
///
/// 提供项目列表侧边栏：在 `onBoot` 阶段解析 `ProjectProviding`，
/// 用 `ProjectSidebarProviding` 替换默认的侧边栏实现，使侧边栏
/// 视图从项目管理服务读取项目列表。
///
/// 符合 Lumi 架构：Provider 声明能力契约（`SidebarProviding` /
/// `ProjectProviding`），插件跨 Provider 组装能力并贡献 UI。
@MainActor
public final class SidebarPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.lumi.plugin.sidebar", category: "Sidebar")
    nonisolated public static let emoji = "📂"
    nonisolated static let verbose = false

    public let id = "com.coffic.lumi.plugin.sidebar"
    /// 依赖项目管理服务先启动。
    public let order = 10
    public let dependencies = ["com.coffic.lumi.plugin.projects"]
    public let metadata = PluginMetadata(
        id: "com.coffic.lumi.plugin.sidebar",
        name: "Project Sidebar",
        description: "Sidebar that lists projects from ProjectProviding",
        category: .project,
        stage: .stable,
        policy: .alwaysOn
    )

    /// 侧边栏服务实例（注册进内核的 SidebarProviding 实现）。
    public let sidebarService: ProjectSidebarProviding

    public init() {
        // 先以空占位创建；onBoot 阶段解析到 ProjectProviding 后完成装配。
        self.sidebarService = ProjectSidebarProviding(projects: PlaceholderProjectProviding())
    }

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error("\(self.t)ProjectProviding not registered; sidebar uses placeholder")
            return
        }

        // 用真实项目管理服务重新装配侧边栏，并替换默认实现。
        let sidebar = ProjectSidebarProviding(projects: projects)
        kernel.unregisterProvider((any SidebarProviding).self)
        try kernel.registerProvider((any SidebarProviding).self, sidebar)

        // 设置窗口「项目」入口：展示现有项目列表。
        if let settings = kernel.resolveProvider((any SettingViewProviding).self) {
            let entry = SettingEntryItem(
                id: "projects",
                title: "项目",
                systemImage: "folder",
                order: 2
            ) { [projects] in
                ProjectsSettingsDetailView(projects: projects)
            }
            settings.addEntries([entry])
        }
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.unregisterProvider((any SidebarProviding).self)
        kernel.resolveProvider((any SettingViewProviding).self)?
            .removeEntries(ids: ["projects"])
    }
}

/// 占位项目管理实现（内核尚未装配 `ProjectProviding` 前的兜底）。
@MainActor
private final class PlaceholderProjectProviding: ProjectProviding {
    private(set) var projects: [Project] = []
    private(set) var currentProject: Project?

    func addObserver(_ callback: @escaping (ProjectProvidingEvent) -> Void) -> any ProjectProvidingObserverHandle {
        NoopObserver(callback: callback)
    }

    func openProject(at url: URL) {}
    func closeCurrentProject() {}
    func addProject(at url: URL) {}
    func removeProject(id: UUID) {}
    func pinProject(id: UUID, isPinned: Bool) {}
    func setCurrentProject(id: UUID?) {}
    func refresh() {}
    func notifyDataChanged() {}
    func persist() {}

    /// 占位实现的空观察者（永不触发）。
    private final class NoopObserver: ProjectProvidingObserverHandle {
        private let callback: (ProjectProvidingEvent) -> Void

        init(callback: @escaping (ProjectProvidingEvent) -> Void) {
            self.callback = callback
        }

        func cancel() {}
    }
}
