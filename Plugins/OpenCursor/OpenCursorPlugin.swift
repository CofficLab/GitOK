import SwiftUI
import MagicKit
import OSLog

class OpenCursorPlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = OpenCursorPlugin()
    /// 日志标识符
    ////  日志标识符
    nonisolated static let emoji = "🖱️"

    /// 是否启用该插件
    static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    static var label: String = "OpenCursor"

    
    private init() {}

    func addToolBarTrailingView() -> AnyView? {
        AnyView(BtnOpenCursorView.shared)
    }
}

// MARK: - PluginRegistrant
extension OpenCursorPlugin {
    @objc static func register() {
        guard enable else { return }

        Task {
            if Self.verbose {
                os_log("\(self.t)🚀 Register OpenCursorPlugin")
            }

            await PluginRegistry.shared.register(id: "OpenCursor", order: 10) {
                OpenCursorPlugin.shared
            }
        }
    }
}
