import MagicKit
import OSLog
import SwiftUI

/// 打开 Finder 插件
/// 提供在工具栏中打开当前项目目录的 Finder 的功能
class OpenFinderPlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = OpenFinderPlugin()
    /// 日志标识符
    nonisolated static let emoji = "📂"

    /// 是否启用该插件
    static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    static var label: String = "OpenFinder"

    private init() {}

    func addToolBarTrailingView() -> AnyView? {
        AnyView(BtnOpenFinderView.shared)
    }
}

// MARK: - PluginRegistrant

extension OpenFinderPlugin {
    @objc static func register() {
        guard enable else { return }

        // 检查用户是否禁用了此插件
        guard PluginSettingsStore.shared.isPluginEnabled("OpenFinder") else {
            if Self.verbose {
                os_log("\(Self.t)⚠️ OpenFinderPlugin is disabled by user settings")
            }
            return
        }

        Task {
            if Self.verbose {
                os_log("\(Self.t)🚀 Register OpenFinderPlugin")
            }

            await PluginRegistry.shared.register(id: "OpenFinder", order: 14) {
                OpenFinderPlugin.shared
            }
        }
    }
}
