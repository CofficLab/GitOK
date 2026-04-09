import MagicKit
import OSLog
import SwiftUI

/// AutoPush 插件：自动推送当前分支到远程仓库
class AutoPushPlugin: NSObject, SuperPlugin, SuperLog {
    @objc static let shared = AutoPushPlugin()

    // MARK: - Logger & Config

    /// 插件专用 Logger
    nonisolated static let logger = Logger(
        subsystem: "com.coffic.gitok",
        category: "plugin.auto-push"
    )

    /// 日志标识 emoji
    nonisolated static let emoji = "🚀"

    /// 是否启用详细日志
    nonisolated static let verbose = false

    // MARK: - Plugin Properties

    /// 是否启用该插件
    @objc static let shouldRegister = true

    /// 插件显示名称
    static var displayName: String = String(localized: "Auto Push", table: "AutoPush")

    /// 插件描述
    static var description: String = String(localized: "Automatically push the current branch to remote repository.", table: "AutoPush")

    /// 插件图标名称
    static var iconName: String = "arrow.up.circle"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var allowUserToggle: Bool = true

    /// 插件默认启用状态
    static var defaultEnabled: Bool = false

    func addStatusBarTrailingView() -> AnyView? {
        return AnyView(AutoPushStatusIcon.shared)
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
