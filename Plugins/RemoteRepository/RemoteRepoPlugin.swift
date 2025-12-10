import MagicCore
import OSLog
import SwiftUI

/// RemoteRepository 插件：在状态栏提供远程仓库管理入口。
class RemoteRepositoryPlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = RemoteRepositoryPlugin()
    static let emoji = "🔗"
    static var label: String = "RemoteRepository"

    private init() {}

    func addStatusBarTrailingView() -> AnyView? {
        AnyView(BtnRemoteRepositoryView.shared)
    }
} 

// MARK: - PluginRegistrant
extension RemoteRepositoryPlugin {
    @objc static func register() {
        Task {
            await PluginRegistry.shared.register(id: "RemoteRepository", order: 27) {
                RemoteRepositoryPlugin.shared
            }
        }
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
