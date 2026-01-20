import MagicKit
import OSLog
import SwiftUI

/// 打开终端插件
/// 提供在工具栏中打开当前项目目录的终端的功能
class OpenTerminalPlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = OpenTerminalPlugin()
    /// 日志标识符
    nonisolated static let emoji = "⌨️"

    /// 是否启用该插件
    static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    static var label: String = "OpenTerminal"

    /// 插件的唯一标识符，用于设置管理
    static var id: String = "OpenTerminal"

    /// 插件显示名称
    static var displayName: String = "OpenTerminal"

    /// 插件描述
    static var description: String = "在终端中打开当前项目目录"

    /// 插件图标名称
    static var iconName: String = "terminal"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var isConfigurable: Bool = true

    private init() {}

    func addToolBarTrailingView() -> AnyView? {
        return AnyView(BtnOpenTerminalView())
    }
}

// MARK: - PluginRegistrant

extension OpenTerminalPlugin {
    @objc static func register() {


        Task {
            if Self.verbose {
                os_log("\(self.t)🚀 Register OpenTerminalPlugin")
            }

            await PluginRegistry.shared.register(id: "OpenTerminal", order: 15) {
                OpenTerminalPlugin()
            }
        }
    }
}
