import MagicKit
import OSLog
import SwiftUI

/// 冲突解决插件：提供可视化的合并冲突解决界面
class ConflictResolverPlugin: NSObject, SuperPlugin {
    /// 插件显示名称
    static var displayName: String = "ConflictResolver"

    /// 插件描述
    static var description: String = "Git 冲突解决"

    /// 插件图标名称
    static var iconName: String = "exclamationmark.triangle"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var allowUserToggle = false
    /// 插件默认启用状态
    static var defaultEnabled: Bool = true

    @objc static let shared = ConflictResolverPlugin()

    /// 是否启用该插件
    @objc static let shouldRegister = false // TODO: 需要正确配置 LibGit2Swift 包依赖

    func addToolBarTrailingView() -> AnyView? {
        return AnyView(ConflictResolverList.shared)
    }

    func addStatusBarLeadingView() -> AnyView? {
        return AnyView(ConflictStatusTile())
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .setInitialTab("ConflictResolver")
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .setInitialTab("ConflictResolver")
        .hideSidebar()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
