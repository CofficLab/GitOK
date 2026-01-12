import MagicKit
import OSLog
import SwiftUI

/// SmartMerge 插件：在状态栏提供合并入口（TileMerge）。
class SmartMergePlugin: SuperPlugin, SuperLog, PluginRegistrant {
    /// 日志标识符
    nonisolated static let emoji = "🔀"

    /// 单例实例
    static let shared = SmartMergePlugin()

    /// 插件标签
    static var label: String = "SmartMerge"

    /// 是否启用该插件
    static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 私有初始化方法
    private init() {}

    /// 添加状态栏尾部视图
    /// - Returns: 返回TileMerge组件的AnyView包装
    func addStatusBarTrailingView() -> AnyView? {
        AnyView(TileMerge.shared)
    }
}

// MARK: - Action

extension SmartMergePlugin {
    /// 插件注册方法
    /// 将SmartMerge插件注册到插件注册表中
    @objc static func register() {
        guard enable else { return }
        
        Task {
            if Self.verbose {
                os_log("\(self.t)🚀 Register SmartMergePlugin")
            }

            await PluginRegistry.shared.register(id: "SmartMerge", order: 25) {
                SmartMergePlugin.shared
            }
        }
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
    ContentLayout()
        .setInitialTab(SmartMergePlugin.label)
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .setInitialTab(SmartMergePlugin.label)
        .hideSidebar()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
