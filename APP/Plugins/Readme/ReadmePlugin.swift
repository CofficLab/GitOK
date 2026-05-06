import MagicKit
import OSLog
import SwiftUI

/// Readme 插件：在状态栏提供 README 入口。
class ReadmePlugin: NSObject, SuperPlugin {
    @objc static let shared = ReadmePlugin()

    /// 是否启用该插件
    @objc static let shouldRegister = true


    /// 插件显示名称
    static var displayName: String = "Readme"

    /// 插件描述
    static var description: String = "在状态栏提供 README 入口"

    /// 插件图标名称
    static var iconName: String = "book"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var allowUserToggle: Bool = true
    /// 插件默认启用状态
    static var defaultEnabled: Bool = true


    

    func addStatusBarTrailingView() -> AnyView? {
        return AnyView(ReadmeStatusIcon.shared)
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
