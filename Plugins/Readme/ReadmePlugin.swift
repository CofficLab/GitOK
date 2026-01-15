import MagicKit
import OSLog
import SwiftUI

/// Readme 插件：在状态栏提供 README 入口。
class ReadmePlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = ReadmePlugin()
    /// 日志标识符
    nonisolated static let emoji = "📖"

    /// 是否启用该插件
    static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    static var label: String = "Readme"

    private init() {}

    func addStatusBarTrailingView() -> AnyView? {
        AnyView(ReadmeStatusIcon.shared)
    }
}

// MARK: - PluginRegistrant

extension ReadmePlugin {
    @objc static func register() {
        guard enable else { return }

        // 检查用户是否禁用了此插件
        guard PluginSettingsStore.shared.isPluginEnabled("Readme") else {
            if Self.verbose {
                os_log("\(Self.t)⚠️ ReadmePlugin is disabled by user settings")
            }
            return
        }

        Task {
            if Self.verbose {
                os_log("\(Self.t)🚀 Register ReadmePlugin")
            }

            await PluginRegistry.shared.register(id: "Readme", order: 28) {
                ReadmePlugin.shared
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
