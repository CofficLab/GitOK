import MagicKit
import OSLog
import SwiftUI

/// 设置按钮插件：在状态栏右侧显示设置按钮
class SettingsButtonPlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = SettingsButtonPlugin()
    /// 日志标识符
    nonisolated static let emoji = "⚙️"

    /// 是否启用该插件
    static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    static var label: String = "SettingsButton"

    /// 插件的唯一标识符，用于设置管理
    static var id: String = "SettingsButton"

    /// 插件显示名称
    static var displayName: String = "SettingsButton"

    /// 插件描述
    static var description: String = "在状态栏右侧显示设置按钮"

    /// 插件图标名称
    static var iconName: String = "gearshape"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var isConfigurable: Bool = false

    private init() {}

    func addStatusBarTrailingView() -> AnyView? {
        AnyView(SettingsButtonView.shared)
    }
}

// MARK: - PluginRegistrant

extension SettingsButtonPlugin {
    @objc static func register() {
        guard enable else { return }

        // 检查用户是否禁用了此插件
        guard PluginSettingsStore.shared.isPluginEnabled("SettingsButton") else {
            if Self.verbose {
                os_log("\(Self.t)⚠️ SettingsButtonPlugin is disabled by user settings")
            }
            return
        }

        Task {
            if Self.verbose {
                os_log("\(Self.t)🚀 Register SettingsButtonPlugin")
            }

            await PluginRegistry.shared.register(id: "SettingsButton", order: 100) {
                SettingsButtonPlugin.shared
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
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
