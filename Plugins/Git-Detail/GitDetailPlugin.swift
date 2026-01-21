import MagicKit
import OSLog
import SwiftUI

/// Git 详情视图插件 - 负责提供 Git 标签页的详情视图
class GitDetailPlugin: NSObject, SuperPlugin, SuperLog {
    /// 日志标识符
    nonisolated static let emoji = "🚄"

    /// 是否启用该插件
    @objc static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    @objc static let shared = GitDetailPlugin()


    /// 插件注册顺序
    static var order: Int = 0

    /// 插件显示名称
    static var displayName: String = "Git Detail"

    /// 插件描述
    static var description: String = "Git 版本控制详情视图"

    /// 插件图标名称
    static var iconName: String = "arrow.up.arrow.down"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var isConfigurable: Bool = false

    private override init() {}

    /// 返回 Git 标签页的详情视图
    func addDetailView(for tab: String) -> AnyView? {
        guard tab == "Git" else { return nil }
        return AnyView(GitDetail.shared)
    }
}


// MARK: - Preview

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
