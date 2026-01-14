import MagicKit
import OSLog
import SwiftUI

class IconPlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = IconPlugin()
    /// 日志标识符
    nonisolated static let emoji = "📣"

    /// 是否启用该插件
    static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    static var label: String = "Icon"
    var isTab: Bool = true

    private init() {}

    func addDetailView() -> AnyView? {
        AnyView(IconDetailLayout.shared)
    }
}

// MARK: - PluginRegistrant

extension IconPlugin {
    @objc static func register() {
        guard enable else { return }

        Task {
            if Self.verbose {
                os_log("\(self.t)🚀 Register IconPlugin")
            }

            await PluginRegistry.shared.register(id: "Icon", order: 2) {
                IconPlugin.shared
            }
        }
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
    ContentLayout()
        .setInitialTab(IconPlugin.label)
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .setInitialTab(IconPlugin.label)
        .hideSidebar()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
