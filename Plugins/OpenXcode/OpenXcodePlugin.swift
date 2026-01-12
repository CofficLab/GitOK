import MagicKit
import OSLog
import SwiftUI

class OpenXcodePlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = OpenXcodePlugin()
    /// 日志标识符
    ////  日志标识符
    nonisolated static let emoji = "🛠️"

    /// 是否启用该插件
    static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    static var label: String = "OpenXcode"

    private init() {}

    func addToolBarTrailingView() -> AnyView? {
        AnyView(BtnOpenXcodeView.shared)
    }
}

// MARK: - PluginRegistrant
extension OpenXcodePlugin {
    @objc static func register() {
        guard enable else { return }

        Task {
            if Self.verbose {
                os_log("\(self.t)🚀 Register OpenXcodePlugin")
            }

            await PluginRegistry.shared.register(id: "OpenXcode", order: 11) {
                OpenXcodePlugin.shared
            }
        }
    }
}
