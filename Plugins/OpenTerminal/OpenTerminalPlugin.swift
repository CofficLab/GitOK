import MagicKit
import OSLog
import SwiftUI

class OpenTerminalPlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = OpenTerminalPlugin()
    /// 日志标识符
    ////  日志标识符
    nonisolated static let emoji = "⌨️"

    /// 是否启用该插件
    static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

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

        Task {
            if Self.verbose {
                os_log("\(self.t)🚀 Register OpenTerminalPlugin")
            }

            await PluginRegistry.shared.register(id: "OpenTerminal", order: 15) {
                OpenTerminalPlugin.shared
            }
        }
    }
}
