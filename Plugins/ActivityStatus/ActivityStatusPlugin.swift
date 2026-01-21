import MagicKit
import OSLog
import SwiftUI

/// 状态栏活动状态插件：展示当前长耗时操作的状态文本。
class ActivityStatusPlugin: NSObject, SuperPlugin {
    /// 是否启用该插件
    @objc static let shouldRegister = true

    @objc static let shared = ActivityStatusPlugin()

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var allowUserToggle = false

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
