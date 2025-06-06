import MagicCore
import OSLog
import SwiftData
import SwiftUI

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
    let banner: BannerProvider
    let icon: IconProvider
    let git: DataProvider
    let repoManager: RepoManager
    let pluginProvider: PluginProvider

    private init(reason: String) {
        os_log("\(Self.onInit)(\(reason))")

        let c = AppConfig.getContainer()

        self.repoManager = RepoManager(modelContext: ModelContext(c))
        
        // Plugins
        let plugins: [SuperPlugin] = [
            GitPlugin(),
            BannerPlugin(),
            IconPlugin(),
     
            OpenXcodePlugin(),
            OpenVSCodePlugin(),
            OpenCursorPlugin(),
            OpenTraePlugin(),
            OpenFinderPlugin(),
            OpenTerminalPlugin(),
            OpenRemotePlugin(),
            SyncPlugin(),
            BranchPlugin.shared,
            CommitPlugin.shared,
            ProjectPickerPlugin.shared
        ]
        
        // Providers
        self.app = AppProvider(repoManager: self.repoManager)
        self.banner = BannerProvider()
        self.icon = IconProvider()
        self.pluginProvider = PluginProvider(plugins: plugins)

        do {
            let projects = try self.repoManager.projectRepo.findAll(sortedBy: .ascending)
            
            self.git = DataProvider(projects: projects, repoManager: self.repoManager)
        } catch let e {
            os_log(.error, "\(e.localizedDescription)")
            self.git = DataProvider(projects: [], repoManager: self.repoManager)
        }
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    })
    .frame(width: 800, height: 800)
}

#Preview("Big Screen") {
    RootView {
        ContentView()
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
