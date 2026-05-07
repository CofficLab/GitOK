import MagicKit
import OSLog
import SwiftUI

/// RemoteRepository 插件：在状态栏提供远程仓库管理入口。
class RemoteRepositoryPlugin: NSObject, SuperPlugin {
    /// 插件显示名称
    static var displayName: String = "RemoteRepository"

    /// 插件描述
    static var description: String = "远程仓库管理"

    /// 插件图标名称
    static var iconName: String = "network"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var allowUserToggle: Bool = false
    /// 插件默认启用状态
    static var defaultEnabled: Bool = true

    @objc static let shared = RemoteRepositoryPlugin()

    /// 是否启用该插件
    @objc static let shouldRegister = true

    func addStatusBarTrailingView() -> AnyView? {
        return AnyView(BtnRemoteRepositoryView.shared)
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
