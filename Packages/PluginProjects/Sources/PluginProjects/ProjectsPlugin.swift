import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderProjects
import ProviderStorage

// MARK: - Projects SuperPlugin

/// 项目插件
///
/// 提供 `ProjectProviding` 服务的默认实现（`ProjectManager`）。
/// 只负责项目管理的逻辑（列表 / 打开 / 移除 / 置顶 / 持久化），不涉及 UI。
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
        description: "GitOK project management (list / open / persist)",
        category: .project,
        stage: .stable,
        policy: .alwaysOn
    )

    /// 项目服务实例（注册进内核的 ProjectProviding 实现）。
    public let projectService: ProjectManager

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
        // 项目数据目录遵循 Lumi 规律：<root>/Projects/
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
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.unregisterProvider((any ProjectProviding).self)
    }
}
