import SwiftUI
import MagicKit
import OSLog

/// LICENSE 插件：在状态栏提供 LICENSE 入口。
class LicensePlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = LicensePlugin()
    /// 日志标识符
    nonisolated static let emoji = "📜"

    /// 是否启用该插件
    static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    static var label: String = "License"

    private init() {}

    func addStatusBarTrailingView() -> AnyView? {
        AnyView(LicenseStatusIcon.shared)
    }
}

// MARK: - PluginRegistrant
extension LicensePlugin {
    @objc static func register() {
        guard enable else { return }

        Task {
            if Self.verbose {
                os_log("\(self.t)🚀 Register LicensePlugin")
            }

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

