import MagicKit
import OSLog
import SwiftUI

class OpenRemotePlugin: SuperPlugin, SuperLog, PluginRegistrant {
    /// 日志标识符
    nonisolated static let emoji = "🌐"

    static let shared = OpenRemotePlugin()
    static var label: String = "OpenRemote"

    /// 是否启用该插件
    static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    private init() {}

    func addToolBarTrailingView() -> AnyView? {
        AnyView(BtnOpenRemoteView.shared)
    }
}

// MARK: - PluginRegistrant
extension OpenRemotePlugin {
    @objc static func register() {
        guard enable else { return }

        Task {
            if Self.verbose {
                os_log("\(self.t)🚀 Register OpenRemotePlugin")
            }

            await PluginRegistry.shared.register(id: "OpenRemote", order: 16) {
                OpenRemotePlugin.shared
            }
        }
    }
}
