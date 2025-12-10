import MagicCore
import OSLog
import SwiftUI

/// SmartFile 插件：在状态栏左侧展示当前文件信息的 Tile。
class SmartFilePlugin: SuperPlugin, SuperLog, PluginRegistrant {
    let emoji = "📣"
    static var label: String = "SmartFile"

    static let shared = SmartFilePlugin()
    
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
        Task {
            await PluginRegistry.shared.register(id: "SmartFile", order: 26) {
                SmartFilePlugin.shared
            }
        }
    }
}
