
import OSLog
import SwiftData
import SwiftUI
import MagicKit

/**
 * 核心服务管理器
 * 用于集中管理应用程序的核心服务和提供者，避免重复初始化
 * 配合 RootView 使用
 */
@MainActor
final class RootBox: SuperLog {
    static let shared = RootBox(reason: "Shared")
    nonisolated static let emoji = "🚉"

    let app: AppProvider
    let icon: IconProvider
    let git: DataProvider
    let repoManager: RepoManager
    let pluginProvider: PluginProvider
    private var verbose = false

    private init(reason: String) {
        if verbose {
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

