import MagicKit
import OSLog
import SwiftUI

class SyncPlugin: NSObject, SuperPlugin {
    /// 插件显示名称
    static var displayName: String = "Sync"

    /// 插件描述
    static var description: String = "同步操作"

    /// 插件图标名称
    static var iconName: String = "arrow.clockwise"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var allowUserToggle: Bool = true
    
    /// 插件默认启用状态
    static var defaultEnabled: Bool = true

    @objc static let shared = SyncPlugin()

    /// 是否启用该插件
    @objc static let shouldRegister = true

    /// 插件注册顺序
    static var order: Int = 9999

    func addToolBarTrailingView() -> AnyView? {
        return AnyView(BtnSyncView.shared)
    }
}
