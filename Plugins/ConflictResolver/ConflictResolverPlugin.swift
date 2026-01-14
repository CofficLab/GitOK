import MagicKit
import OSLog
import SwiftUI

/// 冲突解决插件：提供可视化的合并冲突解决界面
class ConflictResolverPlugin: SuperPlugin, SuperLog, PluginRegistrant {
    /// 日志标识符
    nonisolated static let emoji = "⚔️"

    static let shared = ConflictResolverPlugin()
    static var label: String = "ConflictResolver"

    /// 是否启用该插件
    static let enable = false // TODO: 需要正确配置 LibGit2Swift 包依赖

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    private init() {}

    func addToolBarTrailingView() -> AnyView? {
        AnyView(ConflictResolverList.shared)
    }

    func addStatusBarLeadingView() -> AnyView? {
        AnyView(ConflictStatusTile())
    }
}

// MARK: - PluginRegistrant

extension ConflictResolverPlugin {
    @objc static func register() {
        guard enable else { return }

        Task {
            if Self.verbose {
                os_log("\(self.t)🚀 Register ConflictResolverPlugin")
            }

            await PluginRegistry.shared.register(id: "ConflictResolver", order: 20) {
                ConflictResolverPlugin.shared
            }
        }
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .setInitialTab(ConflictResolverPlugin.label)
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .setInitialTab(ConflictResolverPlugin.label)
        .hideSidebar()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}