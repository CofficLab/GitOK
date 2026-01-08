import MagicKit
import OSLog
import SwiftUI

/// Readme 插件：在状态栏提供 README 入口。
class ReadmePlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = ReadmePlugin()
    let emoji = "📖"
    static var label: String = "Readme"

    private init() {}

    func addStatusBarTrailingView() -> AnyView? {
        AnyView(ReadmeStatusIcon.shared)
    }
} 
// MARK: - PluginRegistrant
extension ReadmePlugin {
    @objc static func register() {
        Task {
            await PluginRegistry.shared.register(id: "Readme", order: 28) {
                ReadmePlugin.shared
            }
        }
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
