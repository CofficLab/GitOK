import MagicKit
import OSLog
import SwiftUI

/// Stash 插件：提供stash暂存功能，包括保存、查看、应用和删除stash
class StashPlugin: SuperPlugin, SuperLog, PluginRegistrant {
    /// 日志标识符
    nonisolated static let emoji = "📦"

    static let shared = StashPlugin()
    static var label: String = "Stash"

    /// 是否启用该插件
    static let enable = false // TODO: 需要正确配置 LibGit2Swift 包依赖

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    private init() {}

    func addToolBarTrailingView() -> AnyView? {
        AnyView(StashList.shared)
    }

    func addStatusBarLeadingView() -> AnyView? {
        AnyView(StashStatusTile())
    }
}

// MARK: - PluginRegistrant

extension StashPlugin {
    @objc static func register() {
        guard enable else { return }

        Task {
            if Self.verbose {
                os_log("\(self.t)🚀 Register StashPlugin")
            }

            await PluginRegistry.shared.register(id: "Stash", order: 21) {
                StashPlugin.shared
            }
        }
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .setInitialTab(StashPlugin.label)
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .setInitialTab(StashPlugin.label)
        .hideSidebar()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}