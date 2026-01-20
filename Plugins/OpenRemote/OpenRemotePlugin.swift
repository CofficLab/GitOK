import MagicKit
import OSLog
import SwiftUI

class OpenRemotePlugin: SuperPlugin, SuperLog {
    /// 日志标识符
    nonisolated static let emoji = "🌐"

    static let shared = OpenRemotePlugin()
    static var label: String = "OpenRemote"

    /// 插件的唯一标识符，用于设置管理
    static var id: String = "OpenRemote"

    /// 插件显示名称
    static var displayName: String = "OpenRemote"

    /// 插件描述
    static var description: String = "打开远程仓库链接"

    /// 插件图标名称
    static var iconName: String = "link"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var isConfigurable: Bool = true

    /// 是否启用该插件
    static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    private init() {}

    func addToolBarTrailingView() -> AnyView? {
        return AnyView(BtnOpenRemoteView.shared)
    }
}

