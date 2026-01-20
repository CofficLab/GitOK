import Cocoa
import MagicKit
import OSLog
import SwiftUI

class OpenKiroPlugin: SuperPlugin, SuperLog {
    static let shared = OpenKiroPlugin()
    /// 日志标识符
    nonisolated static let emoji = "🌊"

    /// 是否启用该插件
    static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    static var label: String = "OpenKiro"

    /// 插件的唯一标识符，用于设置管理
    static var id: String = "OpenKiro"

    /// 插件显示名称
    static var displayName: String = "OpenKiro"

    /// 插件描述
    static var description: String = "在 Kiro 中打开当前项目"

    /// 插件图标名称
    static var iconName: String = "water.waves"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var isConfigurable: Bool = true

    private init() {}

    func addToolBarTrailingView() -> AnyView? {
        return AnyView(BtnOpenKiroView.shared)
    }
}

