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
        
        // Plugins
        let plugins: [SuperPlugin] = [
            GitPlugin.shared,
            BannerPlugin.shared,
            IconPlugin.shared,
    
            OpenCursorPlugin.shared,
            OpenTraePlugin.shared,
            OpenXcodePlugin.shared,
            OpenVSCodePlugin.shared,
            OpenFinderPlugin.shared,
            OpenTerminalPlugin.shared,
            OpenRemotePlugin.shared,
            
            SyncPlugin.shared,
            GitPullPlugin.shared,
            BranchPlugin.shared,
            CommitPlugin.shared,
            ProjectPickerPlugin.shared,
            SmartMergePlugin.shared,
//            QuickMergePlugin.shared,
            SmartFilePlugin.shared,
            RemoteRepositoryPlugin.shared,
            ReadmePlugin.shared
        ]
        
        // Providers
        self.app = AppProvider(repoManager: self.repoManager)
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

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
//            .hideProjectActions()
    }
    .frame(width: 700)
    .frame(height: 700)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
