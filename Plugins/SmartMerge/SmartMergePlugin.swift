import MagicKit
import OSLog
import SwiftUI

/// SmartMerge 插件：在状态栏提供合并入口（TileMerge）。
class SmartMergePlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = SmartMergePlugin()
    let emoji = "📣"
    static var label: String = "SmartMerge"

    private init() {}

    func addStatusBarTrailingView() -> AnyView? {
        AnyView(TileMerge.shared)
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .setInitialTab(SmartMergePlugin.label)
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .setInitialTab(SmartMergePlugin.label)
        .hideSidebar()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}

// MARK: - PluginRegistrant
extension SmartMergePlugin {
    @objc static func register() {
        Task {
            await PluginRegistry.shared.register(id: "SmartMerge", order: 25) {
                SmartMergePlugin.shared
            }
        }
    }
}
