import MagicKit
import OSLog
import SwiftUI

class SmartProjectPlugin: SuperPlugin, SuperLog, PluginRegistrant {
    /// 日志标识符
    ////  日志标识符
    nonisolated static let emoji = "📂"

    /// 是否启用该插件
    static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = false


    static let shared = SmartProjectPlugin()
    static var label: String = "SmartProject"

    private init() {}
    
    func addStatusBarLeadingView() -> AnyView? {
        AnyView(TileProject.shared)
    }
}

// MARK: - PluginRegistrant
extension SmartProjectPlugin {
    @objc static func register() {
        guard enable else { return }

        Task {
            if Self.verbose {
                os_log("\(self.t)🚀 Register SmartProjectPlugin")
            }

            await PluginRegistry.shared.register(id: "SmartProject", order: 29) {
                SmartProjectPlugin.shared
            }
        }
    }
}
