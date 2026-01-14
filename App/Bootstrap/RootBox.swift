
import OSLog
import SwiftData
import SwiftUI
import MagicKit

/// 核心服务管理器
/// 用于集中管理应用程序的核心服务和提供者，避免重复初始化
/// 配合 RootView 使用
@MainActor
final class RootBox: SuperLog {
    /// 日志标识符
    nonisolated static let emoji = "🚉"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    static let shared = RootBox(reason: "Shared")

    /// 应用提供者
    let app: AppProvider

    /// 图标提供者
    let icon: IconProvider

    /// Git 数据提供者
    let git: DataProvider

    /// 仓库管理器
    let repoManager: RepoManager

    /// 插件提供者
    let pluginProvider: PluginProvider

    private init(reason: String) {
        if Self.verbose {
            os_log("\(Self.onInit)(\(reason))")
        }

        let c = AppConfig.getContainer()

        self.repoManager = RepoManager(modelContext: ModelContext(c))
        
        // Providers
        self.app = AppProvider(repoManager: self.repoManager)
        self.icon = IconProvider()
        self.pluginProvider = PluginProvider(autoDiscover: true)

        do {
            let projects = try self.repoManager.projectRepo.findAll(sortedBy: .ascending)
            
            self.git = DataProvider(projects: projects, repoManager: self.repoManager)
        } catch let e {
            os_log(.error, "\(e.localizedDescription)")
            self.git = DataProvider(projects: [], repoManager: self.repoManager)
        }
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .hideTabPicker()
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}

