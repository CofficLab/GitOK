import MagicKit
import OSLog
import SwiftUI

/// LICENSE 插件：在状态栏提供 LICENSE 入口。
class LicensePlugin: NSObject, SuperPlugin {
    @objc static let shared = LicensePlugin()

    /// 是否启用该插件
    @objc static let shouldRegister = false


    /// 插件显示名称
    static var displayName: String = "License"

    /// 插件描述
    static var description: String = "在状态栏提供 LICENSE 入口"

    /// 插件图标名称
    static var iconName: String = "doc.on.doc"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var allowUserToggle: Bool = true



    override private init() {}

    func addStatusBarTrailingView() -> AnyView? {
        return AnyView(LicenseStatusIcon.shared)
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
