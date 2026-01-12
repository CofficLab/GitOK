import MagicKit
import OSLog
import SwiftUI

class OpenFinderPlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = OpenFinderPlugin()
    /// 日志标识符
    ////  日志标识符
    nonisolated static let emoji = "📂"

    /// 是否启用该插件
    static let enable = false

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

        Task {
            if Self.verbose {
                os_log("\(self.t)🚀 Register OpenFinderPlugin")
            }

            await PluginRegistry.shared.register(id: "OpenFinder", order: 14) {
                OpenFinderPlugin.shared
            }
        }
    }
}
