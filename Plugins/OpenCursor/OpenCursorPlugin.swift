import Cocoa
import MagicKit
import OSLog
import SwiftUI

class OpenCursorPlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = OpenCursorPlugin()
    /// 日志标识符
    nonisolated static let emoji = "🖱️"

    /// 是否启用该插件
    static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    static var label: String = "OpenCursor"

    /// 插件的唯一标识符，用于设置管理
    static var id: String = "OpenCursor"

    /// 插件显示名称
    static var displayName: String = "OpenCursor"

    /// 插件描述
    static var description: String = "在 Cursor 中打开当前项目"

    /// 插件图标名称
    static var iconName: String = "cursor.rays"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var isConfigurable: Bool = true

    private init() {}

    func addToolBarTrailingView() -> AnyView? {
        return AnyView(BtnOpenCursorView.shared)
    }
}

// MARK: - PluginRegistrant

extension OpenCursorPlugin {
    @objc static func register() {

        // 检查 Cursor 是否安装
        guard isCursorInstalled() else {
                os_log("\(Self.t)⚠️ Cursor is not installed, skipping OpenCursorPlugin registration")
            return
        }

        Task {

            await PluginRegistry.shared.register(id: "OpenCursor", order: 10) {
                OpenCursorPlugin.shared
            }
        }
    }

    /// 检查 Cursor 是否已安装
    /// - Returns: 如果 Cursor 已安装返回 true，否则返回 false
    private static func isCursorInstalled() -> Bool {
        // 方法1: 通过 Bundle Identifier 检查
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "dev.cursor.Cursor") {
                os_log("\(Self.t)✅ Found Cursor at: \(appURL.path)")
            return true
        }

        // 方法2: 通过应用路径检查（作为备选）
        let applicationPaths = [
            "/Applications/Cursor.app",
            "/Applications/Cursor.app/Contents/MacOS/Cursor",
            NSHomeDirectory() + "/Applications/Cursor.app"
        ]

        for path in applicationPaths {
            if FileManager.default.fileExists(atPath: path) {
                    os_log("\(Self.t)✅ Found Cursor at: \(path)")
                return true
            }
        }

            os_log("\(Self.t)❌ Cursor not found in system")

        return false
    }
}
