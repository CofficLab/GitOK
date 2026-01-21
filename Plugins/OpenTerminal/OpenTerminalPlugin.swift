import MagicKit
import OSLog
import SwiftUI

/// 打开终端插件
/// 提供在工具栏中打开当前项目目录的终端的功能
class OpenTerminalPlugin: NSObject, SuperPlugin {
    @objc static let shared = OpenTerminalPlugin()

    /// 是否启用该插件
    @objc static let shouldRegister = false


    /// 插件显示名称
    static var displayName: String = "OpenTerminal"

    /// 插件描述
    static var description: String = "在终端中打开当前项目目录"

    /// 插件图标名称
    static var iconName: String = "terminal"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var allowUserToggle: Bool = true


    override private init() {}

    func addToolBarTrailingView() -> AnyView? {
        return AnyView(BtnOpenTerminalView())
    }
}
