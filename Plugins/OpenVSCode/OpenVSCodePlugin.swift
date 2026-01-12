import MagicKit
import OSLog
import SwiftUI

class OpenVSCodePlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = OpenVSCodePlugin()
    /// 日志标识符
    ////  日志标识符
    nonisolated static let emoji = "💻"

    /// 是否启用该插件
    static let enable = false

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    static var label: String = "OpenVSCode"

    private init() {}

    func addToolBarTrailingView() -> AnyView? {
        AnyView(BtnOpenVSCodeView.shared)
    }
}

// MARK: - PluginRegistrant
extension OpenVSCodePlugin {
    @objc static func register() {
        guard enable else { return }

        Task {
            if Self.verbose {
                os_log("\(self.t)🚀 Register OpenVSCodePlugin")
            }

            await PluginRegistry.shared.register(id: "OpenVSCode", order: 12) {
                OpenVSCodePlugin.shared
            }
        }
    }
}
