import MagicKit
import OSLog
import SwiftUI

/// Git 标签页插件 - 负责在工具栏中提供 "Git" 标签页
class GitTabPlugin: NSObject, SuperPlugin, SuperLog {
    /// 日志标识符
    nonisolated static let emoji = "🚄"

    /// 是否启用该插件
    @objc static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    @objc static let shared = GitTabPlugin()

    static var label: String = "GitTab"


    /// 插件注册顺序
    static var order: Int = 0

    /// 插件显示名称
    static var displayName: String = "Git"

    /// 插件描述
    static var description: String = "Git 版本控制"

    /// 插件图标名称
    static var iconName: String = "arrow.up.arrow.down"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var isConfigurable: Bool = false

    private override init() {}

    /// 返回标签页名称
    func addTabItem() -> String? {
        return "Git"
    }
}
