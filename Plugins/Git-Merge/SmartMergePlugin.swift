import MagicKit
import OSLog
import SwiftUI

/// SmartMerge 插件：在状态栏提供合并入口（TileMerge）。
class SmartMergePlugin: NSObject, SuperPlugin {
    /// 插件显示名称
    static var displayName: String = "SmartMerge"

    /// 插件描述
    static var description: String = "智能合并工具"

    /// 插件图标名称
    static var iconName: String = "arrow.merge"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var allowUserToggle: Bool = true



    /// 单例实例
    @objc static let shared = SmartMergePlugin()

    /// 是否启用该插件
    @objc static let shouldRegister = true


    /// 私有初始化方法
    

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
