import MagicKit
import OSLog
import SwiftUI

/// Branch 插件：提供分支列表视图（工具栏右侧）并在状态栏左侧展示当前分支。
class BranchPlugin: SuperPlugin, SuperLog, PluginRegistrant {
    /// 日志标识符
    nonisolated static let emoji = "🌿"

    static let shared = BranchPlugin()
    static var label: String = "Branch"

    /// 是否启用该插件
    static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    private init() {}

    func addToolBarTrailingView() -> AnyView? {
        AnyView(BranchesView.shared)
    }

    func addStatusBarLeadingView() -> AnyView? {
        AnyView(BranchStatusTile())
    }
}

// MARK: - PluginRegistrant

extension BranchPlugin {
    @objc static func register() {
        guard enable else { return }

        Task {
            if Self.verbose {
                os_log("\(self.t)🚀 Register BranchPlugin")
            }

            await PluginRegistry.shared.register(id: "Branch", order: 22) {
                BranchPlugin.shared
            }
        }
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .setInitialTab(BranchPlugin.label)
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .setInitialTab(BranchPlugin.label)
        .hideSidebar()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
