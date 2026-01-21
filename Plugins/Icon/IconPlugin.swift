import MagicKit
import OSLog
import SwiftUI

class IconPlugin: NSObject, SuperPlugin, SuperLog {
    /// 日志标识符
    nonisolated static let emoji = "📣"

    /// 是否启用该插件
    @objc static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    @objc static let shared = IconPlugin()
    static var label: String = "IconDetail"


    /// 插件显示名称
    static var displayName: String = "Icon Detail"

    /// 插件描述
    static var description: String = "图标详情视图"

    /// 插件图标名称
    static var iconName: String = "photo"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var isConfigurable: Bool = false

    private override init() {}

    /// 返回 Icon 标签页的详情视图
    func addDetailView(for tab: String) -> AnyView? {
        guard tab == "Icon" else { return nil }
        return AnyView(IconDetailLayout.shared)
    }
}


// MARK: - Preview

#Preview("App - Small Screen") {
    ContentLayout()
        .setInitialTab(IconPlugin.label)
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .setInitialTab(IconPlugin.label)
        .hideSidebar()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
