import MagicKit
import OSLog
import SwiftUI

class OpenTraePlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = OpenTraePlugin()
    /// 日志标识符
    ////  日志标识符
    nonisolated static let emoji = "🤖"

    /// 是否启用该插件
    static let enable = false

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    static var label: String = "OpenTrae"

    private init() {}

    func addToolBarTrailingView() -> AnyView? {
        AnyView(BtnOpenTraeView.shared)
    }
}

// MARK: - PluginRegistrant
extension OpenTraePlugin {
    @objc static func register() {
        guard enable else { return }

        Task {
            if Self.verbose {
                os_log("\(self.t)🚀 Register OpenTraePlugin")
            }

            await PluginRegistry.shared.register(id: "OpenTrae", order: 13) {
                OpenTraePlugin.shared
            }
        }
    }
}
