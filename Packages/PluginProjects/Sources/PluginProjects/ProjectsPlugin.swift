import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderCloneRepository
import ProviderProjects
import ProviderSettingView
import ProviderSidebar
import ProviderStorage
import ProviderToolbar

// MARK: - Projects SuperPlugin

/// 项目插件
///
/// 承担两项职责：
/// 1. 提供 `ProjectProviding` 服务的默认实现（`ProjectManager`），负责项目
///    管理的逻辑（列表 / 打开 / 移除 / 置顶 / 持久化）。
/// 2. 提供项目列表侧边栏：在 `onBoot` 阶段用 `ProjectSidebarProviding` 替换
///    默认的 `SidebarProviding`，并往设置窗口注入「项目」入口。
///
/// 存储目录遵循 Lumi 规律：通过 `StorageProviding.pluginDataDirectory(for:)`
/// 取得 `<Application Support>/<bundleID>/db_<env>_v<major>/Projects/`，
/// 项目列表写入该目录下的 `projects.json`。
@MainActor
public final class ProjectsPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.lumi.plugin.projects", category: "Projects")
    nonisolated public static let emoji = "📁"
    nonisolated static let verbose = false

    public let id = "com.coffic.lumi.plugin.projects"
    /// 先于依赖 ProjectProviding 的其他插件启动（基础服务）。
    public let order = 0
    public let metadata = PluginMetadata(
        id: "com.coffic.lumi.plugin.projects",
        name: "Projects",
        description: "GitOK project management (list / open / persist) and project sidebar",
        category: .project,
        stage: .stable,
        policy: .required
    )

    /// 项目服务实例（注册进内核的 ProjectProviding 实现）。
    public let projectService: ProjectManager

    /// 侧边栏服务实例（注册进内核的 SidebarProviding 实现）。
    public private(set) var sidebarService: ProjectSidebarProviding?

    public init(storeURL: URL? = nil) {
        if let storeURL {
            self.projectService = ProjectManager(storeURL: storeURL)
        } else {
            // 无显式目录时，用一个临时占位；onBoot 阶段解析 StorageProviding
            // 后会用真实目录重建。
            let placeholder = FileManager.default.temporaryDirectory
                .appendingPathComponent("LumiProjectsPlaceholder", isDirectory: true)
                .appendingPathComponent("projects.json")
            self.projectService = ProjectManager(storeURL: placeholder)
        }
    }

    public func onBoot(kernel: KernelCoreContainer) throws {
        // 1) 项目数据目录遵循 Lumi 规律：<root>/Projects/
        if let storage = kernel.resolveProvider((any StorageProviding).self) {
            let directory = storage.pluginDataDirectory(for: "Projects")
            let storeURL = directory.appendingPathComponent("projects.json", isDirectory: false)

            // 用真实目录替换占位目录并重新加载磁盘上的项目列表。
            projectService.setStoreURL(storeURL)
            kernel.unregisterProvider((any ProjectProviding).self)
            try kernel.registerProvider((any ProjectProviding).self, projectService)
        } else {
            Self.logger.error("\(self.t)StorageProviding not registered; ProjectProviding left unregistered")
        }

        // 2) 项目列表侧边栏：用 ProjectSidebarProviding 替换默认实现。
        let projects = kernel.resolveProvider((any ProjectProviding).self) ?? projectService
        // 克隆仓库能力（PluginCloneRepository 注册）；无则为 nil（不显示克隆入口）。
        let cloneProvider = kernel.resolveProvider((any CloneRepositoryProviding).self)

        let sidebar = ProjectSidebarProviding(projects: projects, cloneProvider: cloneProvider)
        self.sidebarService = sidebar
        kernel.unregisterProvider((any SidebarProviding).self)
        try kernel.registerProvider((any SidebarProviding).self, sidebar)

        // 3) 设置窗口「项目」入口：展示现有项目列表。
        if let settings = kernel.resolveProvider((any SettingViewProviding).self) {
            let entry = SettingEntryItem(
                id: "projects",
                title: LumiPluginLocalization.string("Projects", bundle: .module),
                systemImage: "folder",
                order: 2
            ) { [projects] in
                ProjectsSettingsDetailView(projects: projects)
            }
            settings.addEntries([entry])
        }

        // 4) 工具栏中间项目控件：显示当前项目，点击弹出项目列表（Lumi 风格）。
        if let toolbar = kernel.resolveProvider((any ToolbarProviding).self) {
            toolbar.addToolbarItems([
                ToolbarItem(
                    id: "\(id).toolbar",
                    title: LumiPluginLocalization.string("Project", bundle: .module),
                    placement: .center,
                    category: .project,
                    order: 5
                ) {
                    ProjectToolbarControlView(projects: projects)
                },
            ])
        }
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.unregisterProvider((any ProjectProviding).self)
        kernel.unregisterProvider((any SidebarProviding).self)
        kernel.resolveProvider((any SettingViewProviding).self)?
            .removeEntries(ids: ["projects"])
        kernel.resolveProvider((any ToolbarProviding).self)?
            .removeToolbarItems(ids: ["\(id).toolbar"])
        sidebarService = nil
    }
}
