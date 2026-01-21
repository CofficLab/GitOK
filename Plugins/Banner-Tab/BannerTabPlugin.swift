import MagicKit
import OSLog
import SwiftUI

/// Banner 标签页插件 - 负责在工具栏中提供 "Banner" 标签页
class BannerTabPlugin: NSObject, SuperPlugin, SuperLog {
    /// 日志标识符
    nonisolated static let emoji = "📣"

    /// 是否启用该插件
    @objc static let shouldRegister = false

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    @objc static let shared = BannerTabPlugin()

    /// 插件注册顺序
    static var order: Int = 2

    /// 插件显示名称
    static var displayName: String = "Banner"

    /// 插件描述
    static var description: String = "生成项目横幅图片"

    /// 插件图标名称
    static var iconName: String = "photo"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var allowUserToggle: Bool = false

    override private init() {}

    /// 返回标签页名称
    func addTabItem() -> String? {
        return "Banner"
    }
}
