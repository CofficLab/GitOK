import Cocoa
import MagicKit
import OSLog
import SwiftUI

class OpenKiroPlugin: NSObject, SuperPlugin {
    @objc static let shared = OpenKiroPlugin()

    /// 是否启用该插件
    @objc static let shouldRegister = true

    /// 插件显示名称
    static var displayName: String = "OpenKiro"

    /// 插件描述
    static var description: String = "在 Kiro 中打开当前项目"

    /// 插件图标名称
    static var iconName: String = "water.waves"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var allowUserToggle = true

    func addToolBarTrailingView() -> AnyView? {
        return AnyView(BtnOpenKiroView.shared)
    }
}
