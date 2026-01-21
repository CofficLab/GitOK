import MagicKit
import OSLog
import SwiftUI

/// Banner 标签页插件 - 负责在工具栏中提供 "Banner" 标签页
class BannerTabPlugin: NSObject, SuperPlugin {
    /// 是否启用该插件
    @objc static let shouldRegister = true

    @objc static let shared = BannerTabPlugin()

    /// 插件注册顺序
    static var order = 2

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var allowUserToggle = false

    /// 返回标签页名称
    func addTabItem() -> String? {
        return "Banner"
    }
}
