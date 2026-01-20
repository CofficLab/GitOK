import MagicKit
import OSLog
import SwiftUI

/// 冲突解决插件：提供可视化的合并冲突解决界面
class ConflictResolverPlugin: NSObject, SuperPlugin, SuperLog {
    /// 插件的唯一标识符，用于设置管理
    static var id: String = "ConflictResolver"

    /// 插件显示名称
    static var displayName: String = "ConflictResolver"

    /// 插件描述
    static var description: String = "Git 冲突解决"

    /// 插件图标名称
    static var iconName: String = "exclamationmark.triangle"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var isConfigurable: Bool = false
    /// 日志标识符
    nonisolated static let emoji = "⚔️"

    @objc static let shared = ConflictResolverPlugin()
    static var label: String = "ConflictResolver"

    /// 是否启用该插件
    static let enable = false // TODO: 需要正确配置 LibGit2Swift 包依赖

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    private override init() {}

    func addToolBarTrailingView() -> AnyView? {
        return AnyView(ConflictResolverList.shared)
    }

    func addStatusBarLeadingView() -> AnyView? {
        return AnyView(ConflictStatusTile())
    }
}


#Preview("App - Small Screen") {
    ContentLayout()
        .setInitialTab(ConflictResolverPlugin.label)
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .setInitialTab(ConflictResolverPlugin.label)
        .hideSidebar()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}