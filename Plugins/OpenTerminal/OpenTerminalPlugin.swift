import MagicKit
import OSLog
import SwiftUI

/// 打开终端插件
/// 提供在工具栏中打开当前项目目录的终端的功能
class OpenTerminalPlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = OpenTerminalPlugin()
    /// 日志标识符
    nonisolated static let emoji = "⌨️"

    /// 是否启用该插件
    static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    static var label: String = "OpenTerminal"

    private init() {}

    func addToolBarTrailingView() -> AnyView? {
        AnyView(BtnOpenTerminalView())
    }
}

// MARK: - PluginRegistrant

extension OpenTerminalPlugin {
    @objc static func register() {
        guard enable else { return }

        // 检查用户是否禁用了此插件
        guard PluginSettingsStore.shared.isPluginEnabled("OpenTerminal") else {
            if Self.verbose {
                os_log("\(Self.t)⚠️ OpenTerminalPlugin is disabled by user settings")
            }
            return
        }

        Task {
            if Self.verbose {
                os_log("\(self.t)🚀 Register OpenTerminalPlugin")
            }

            await PluginRegistry.shared.register(id: "OpenTerminal", order: 15) {
                OpenTerminalPlugin()
            }
        }
    }
}
