
import MagicKit
import OSLog
import SwiftUI

/// Banner 插件类
/// 负责管理和提供应用横幅生成功能
class BannerPlugin: SuperPlugin, SuperLog, PluginRegistrant {
    /// 日志标识符
    nonisolated static let emoji = "📣"

    /// 是否启用该插件
    static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    static let shared = BannerPlugin()
    static var label: String = "Banner"
    var isTab: Bool = true

    private init() {}

    func addDetailView() -> AnyView? {
        AnyView(BannerDetailLayout.shared.environmentObject(BannerProvider.shared))
    }
}

// MARK: - PluginRegistrant

extension BannerPlugin {
    @objc static func register() {
        guard enable else { return }

        Task {
            if Self.verbose {
                os_log("\(self.t)🚀 Register BannerPlugin")
            }

            await PluginRegistry.shared.register(id: "Banner", order: 1) {
                BannerPlugin.shared
            }
        }
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .hideTabPicker()
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}
