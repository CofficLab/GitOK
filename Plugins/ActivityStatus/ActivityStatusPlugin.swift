import MagicKit
import SwiftUI
import OSLog

/// 状态栏活动状态插件：展示当前长耗时操作的状态文本。
class ActivityStatusPlugin: SuperPlugin, SuperLog, PluginRegistrant {
    /// 日志标识符
    nonisolated static let emoji = "⌛️"

    /// 是否启用该插件
    static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = false


    static let shared = ActivityStatusPlugin()
    static let label = "ActivityStatus"

    private init() {}

    func addStatusBarTrailingView() -> AnyView? {
        AnyView(ActivityStatusTile())
    }
}

// MARK: - PluginRegistrant
extension ActivityStatusPlugin {
    @objc static func register() {
        guard enable else { return }

        Task {
            if Self.verbose {
                os_log("\(self.t)🚀 Register ActivityStatusPlugin")
            }

            await PluginRegistry.shared.register(id: Self.label, order: 10) {
                ActivityStatusPlugin.shared
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

