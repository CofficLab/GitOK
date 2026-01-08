import MagicKit
import SwiftUI

/// 状态栏活动状态插件：展示当前长耗时操作的状态文本。
class ActivityStatusPlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = ActivityStatusPlugin()
    static let label = "ActivityStatus"
    let emoji = "⌛️"

    private init() {}

    func addStatusBarTrailingView() -> AnyView? {
        AnyView(ActivityStatusTile())
    }
}

// MARK: - PluginRegistrant
extension ActivityStatusPlugin {
    @objc static func register() {
        Task {
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

