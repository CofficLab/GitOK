import MagicCore
import SwiftUI

/// LICENSE 插件：在状态栏提供 LICENSE 入口。
class LicensePlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = LicensePlugin()
    let emoji = "📜"
    static var label: String = "License"

    private init() {}

    func addStatusBarTrailingView() -> AnyView? {
        AnyView(LicenseStatusIcon.shared)
    }
}

// MARK: - PluginRegistrant
extension LicensePlugin {
    @objc static func register() {
        Task {
            await PluginRegistry.shared.register(id: "License", order: 29) {
                LicensePlugin.shared
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

