import OSLog
import SwiftData
import MagicCore
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
    let git: GitProvider
    let c: ModelContainer
    
    private init(reason: String) {
        os_log("\(Self.onInit)(\(reason))")
        
        self.c = AppConfig.getContainer()
        
        // Providers
        self.app = AppProvider()
        self.git = GitProvider()
        self.banner = BannerProvider()
        self.icon = IconProvider()
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

