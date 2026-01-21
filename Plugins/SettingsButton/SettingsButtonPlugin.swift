import MagicKit
import OSLog
import SwiftUI

/// 设置按钮插件：在状态栏右侧显示设置按钮
class SettingsButtonPlugin: NSObject, SuperPlugin {
    @objc static let shared = SettingsButtonPlugin()

    /// 是否启用该插件
    @objc static let shouldRegister = false


    /// 插件显示名称
    static var displayName: String = "SettingsButton"

    /// 插件描述
    static var description: String = "在状态栏右侧显示设置按钮"

    /// 插件图标名称
    static var iconName: String = "gearshape"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var allowUserToggle: Bool = false


    override private init() {}

    func addStatusBarTrailingView() -> AnyView? {
        AnyView(SettingsButtonView.shared)
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
