import MagicKit
import OSLog
import SwiftUI

/// LICENSE 插件：在状态栏提供 LICENSE 入口。
class LicensePlugin: NSObject, SuperPlugin, SuperLog {
    @objc static let shared = LicensePlugin()
    /// 日志标识符
    nonisolated static let emoji = "📜"

    /// 是否启用该插件
    @objc static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    /// 插件显示名称
    static var displayName: String = "License"

    /// 插件描述
    static var description: String = "在状态栏提供 LICENSE 入口"

    /// 插件图标名称
    static var iconName: String = "doc.on.doc"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var isConfigurable: Bool = true

    ///  插件默认启用状态
    static var defaultEnabled: Bool = false

    ///  插件默认启用状态

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
