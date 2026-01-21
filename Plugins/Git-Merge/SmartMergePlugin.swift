import MagicKit
import OSLog
import SwiftUI

/// SmartMerge 插件：在状态栏提供合并入口（TileMerge）。
class SmartMergePlugin: NSObject, SuperPlugin, SuperLog {
    /// 插件显示名称
    static var displayName: String = "SmartMerge"

    /// 插件描述
    static var description: String = "智能合并工具"

    /// 插件图标名称
    static var iconName: String = "arrow.merge"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var isConfigurable: Bool = true

    ///  插件默认启用状态
    static var defaultEnabled: Bool = false

    /// 日志标识符
    nonisolated static let emoji = "🔀"

    /// 单例实例
    @objc static let shared = SmartMergePlugin()

    /// 是否启用该插件
    @objc static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    /// 私有初始化方法
    override private init() {}

    /// 添加状态栏尾部视图
    /// - Returns: 返回TileMerge组件的AnyView包装
    func addStatusBarTrailingView() -> AnyView? {
        return AnyView(TileMerge.shared)
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
    ContentLayout()
        .setInitialTab("SmartMerge")
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .setInitialTab("SmartMerge")
        .hideSidebar()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
