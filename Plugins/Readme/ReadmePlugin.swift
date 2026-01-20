import MagicKit
import OSLog
import SwiftUI

/// Readme 插件：在状态栏提供 README 入口。
class ReadmePlugin: SuperPlugin, SuperLog {
    static let shared = ReadmePlugin()
    /// 日志标识符
    nonisolated static let emoji = "📖"

    /// 是否启用该插件
    static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    static var label: String = "Readme"

    /// 插件的唯一标识符，用于设置管理
    static var id: String = "Readme"

    /// 插件显示名称
    static var displayName: String = "Readme"

    /// 插件描述
    static var description: String = "在状态栏提供 README 入口"

    /// 插件图标名称
    static var iconName: String = "book"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var isConfigurable: Bool = true

    private init() {}

    func addStatusBarTrailingView() -> AnyView? {
        return AnyView(ReadmeStatusIcon.shared)
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
