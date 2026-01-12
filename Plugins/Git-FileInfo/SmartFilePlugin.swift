import MagicKit
import OSLog
import SwiftUI

/// SmartFile 插件：在状态栏左侧展示当前文件信息的 Tile。
class SmartFilePlugin: SuperPlugin, SuperLog, PluginRegistrant {
    /// 日志标识符
    ////  日志标识符
    nonisolated static let emoji = "📄"

    /// 是否启用该插件
    static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = false


    static let shared = SmartFilePlugin()
    static var label: String = "SmartFile"
    
    private init() {}
    
    func addStatusBarLeadingView() -> AnyView? {
        AnyView(TileFile.shared)
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}

// MARK: - PluginRegistrant
extension SmartFilePlugin {
    @objc static func register() {
        guard enable else { return }

        Task {
            if Self.verbose {
                os_log("\(self.t)🚀 Register SmartFilePlugin")
            }

            await PluginRegistry.shared.register(id: "SmartFile", order: 26) {
                SmartFilePlugin.shared
            }
        }
    }
}
