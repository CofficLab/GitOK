import MagicKit
import OSLog
import SwiftUI

class OpenRemotePlugin: NSObject, SuperPlugin {
    @objc static let shared = OpenRemotePlugin()

    /// 插件显示名称
    static var displayName: String = "OpenRemote"

    /// 插件描述
    static var description: String = "打开远程仓库链接"

    /// 插件图标名称
    static var iconName: String = "link"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var allowUserToggle = true
    /// 插件默认启用状态
    static var defaultEnabled: Bool = true

    /// 是否启用该插件
    @objc static let shouldRegister = true

    func addToolBarTrailingView() -> AnyView? {
        return AnyView(BtnOpenRemoteView.shared)
    }
}
