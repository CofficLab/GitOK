import MagicKit
import OSLog
import SwiftUI

/// Icon 标签页插件 - 负责在工具栏中提供 "Icon" 标签页
class IconTabPlugin: NSObject, SuperPlugin {

    /// 是否启用该插件
    @objc static let shouldRegister = true


    @objc static let shared = IconTabPlugin()



    /// 插件注册顺序
    static var order: Int = 1

    /// 插件显示名称
    static var displayName: String = "Icon"

    /// 插件描述
    static var description: String = "图标管理"

    /// 插件图标名称
    static var iconName: String = "photo"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var allowUserToggle: Bool = false
    /// 插件默认启用状态
    static var defaultEnabled: Bool = true


    private override init() {}

    /// 返回标签页名称
    func addTabItem() -> String? {
        return "Icon"
    }
}
