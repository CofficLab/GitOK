import MagicKit
import OSLog
import SwiftUI

/// SmartFile 插件：在状态栏左侧展示当前文件信息的 Tile。
class SmartFilePlugin: SuperPlugin, SuperLog, PluginRegistrant {
    /// 日志标识符
    nonisolated static let emoji = "📄"

    /// 是否启用该插件
    static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    static let shared = SmartFilePlugin()
    static var label: String = "SmartFile"

    /// 插件的唯一标识符，用于设置管理
    static var id: String = "SmartFile"

    /// 插件显示名称
    static var displayName: String = "SmartFile"

    /// 插件描述
    static var description: String = "在状态栏左侧展示当前文件信息"

    /// 插件图标名称
    static var iconName: String = "doc.text"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var isConfigurable: Bool = false

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
