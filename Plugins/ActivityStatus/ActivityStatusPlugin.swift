import MagicKit
import OSLog
import SwiftUI

/// 状态栏活动状态插件：展示当前长耗时操作的状态文本。
class ActivityStatusPlugin: NSObject, SuperPlugin, SuperLog {
    /// 日志标识符
    nonisolated static let emoji = "⌛️"

    /// 是否启用该插件
    @objc static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    @objc static let shared = ActivityStatusPlugin()
    static let label = "ActivityStatus"

    /// 插件的唯一标识符，用于设置管理
    static var id: String = "ActivityStatus"

    /// 插件显示名称
    static var displayName: String = "ActivityStatus"

    /// 插件描述
    static var description: String = "在状态栏显示当前长耗时操作的状态"

    /// 插件图标名称
    static var iconName: String = "hourglass"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var isConfigurable: Bool = false

    private override init() {}

    func addStatusBarCenterView() -> AnyView? {
        AnyView(ActivityStatusTile())
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
