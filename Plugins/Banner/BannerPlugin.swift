
import MagicKit
import OSLog
import SwiftUI

/// Banner 插件类
/// 负责管理和提供应用横幅生成功能
class BannerPlugin: NSObject, SuperPlugin, SuperLog {
    /// 日志标识符
    nonisolated static let emoji = "📣"

    /// 是否启用该插件
    @objc static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    @objc static let shared = BannerPlugin()

    /// 插件注册顺序
    static var order: Int = 2


    /// 插件显示名称
    static var displayName: String = "Banner Detail"

    /// 插件描述
    static var description: String = "Banner 详情视图"

    /// 插件图标名称
    static var iconName: String = "photo"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var isConfigurable: Bool = false

    private override init() {}

    /// 返回 Banner 标签页的详情视图
    func addDetailView(for tab: String) -> AnyView? {
        guard tab == "Banner" else { return nil }
        return AnyView(BannerDetailLayout.shared.environmentObject(BannerProvider.shared))
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
        .hideTabPicker()
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}
