import MagicKit
import OSLog
import SwiftUI

/// RemoteRepository 插件：在状态栏提供远程仓库管理入口。
class RemoteRepositoryPlugin: SuperPlugin, SuperLog, PluginRegistrant {
    /// 日志标识符
    nonisolated static let emoji = "🔗"

    static let shared = RemoteRepositoryPlugin()
    static var label: String = "RemoteRepository"

    /// 是否启用该插件
    static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    private init() {}

    func addStatusBarTrailingView() -> AnyView? {
        AnyView(BtnRemoteRepositoryView.shared)
    }
} 

// MARK: - PluginRegistrant
extension RemoteRepositoryPlugin {
    @objc static func register() {
        guard enable else { return }

        Task {
            if Self.verbose {
                os_log("\(self.t)🚀 Register RemoteRepoPlugin")
            }

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
