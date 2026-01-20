import Cocoa
import MagicKit
import OSLog
import SwiftUI

class OpenKiroPlugin: SuperPlugin, SuperLog, PluginRegistrant {
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

// MARK: - PluginRegistrant

extension OpenKiroPlugin {
    @objc static func register() {

        // 检查 Kiro 是否安装
        guard isKiroInstalled() else {
                os_log("\(Self.t)⚠️ Kiro is not installed, skipping OpenKiroPlugin registration")
            return
        }

        Task {

            await PluginRegistry.shared.register(id: "OpenKiro", order: 15) {
                OpenKiroPlugin.shared
            }
        }
    }

    /// 检查 Kiro 是否已安装
    /// - Returns: 如果 Kiro 已安装返回 true，否则返回 false
    private static func isKiroInstalled() -> Bool {
        // 方法1: 通过 Bundle Identifier 检查
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "dev.kiro.desktop") {
                os_log("\(Self.t)✅ Found Kiro at: \(appURL.path)")
            return true
        }

        // 方法2: 通过应用路径检查（作为备选）
        let applicationPaths = [
            "/Applications/Kiro.app",
            NSHomeDirectory() + "/Applications/Kiro.app"
        ]

        for path in applicationPaths {
            if FileManager.default.fileExists(atPath: path) {
                    os_log("\(Self.t)✅ Found Kiro at: \(path)")
                return true
            }
        }

            os_log("\(Self.t)❌ Kiro not found in system")

        return false
    }
}
