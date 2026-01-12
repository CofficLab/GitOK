import MagicKit
import OSLog
import SwiftUI

class SyncPlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = SyncPlugin()
    /// 日志标识符
    ////  日志标识符
    nonisolated static let emoji = "🔄"

    /// 是否启用该插件
    static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    static var label: String = "Sync"

    private init() {}

    func addToolBarTrailingView() -> AnyView? {
        AnyView(BtnSyncView.shared)
    }
}

// MARK: - PluginRegistrant
extension SyncPlugin {
    @objc static func register() {
        guard enable else { return }

        Task {
            if Self.verbose {
                os_log("\(self.t)🚀 Register SyncPlugin")
            }

            await PluginRegistry.shared.register(id: "Sync", order: 20) {
                SyncPlugin.shared
            }
        }
    }
}
