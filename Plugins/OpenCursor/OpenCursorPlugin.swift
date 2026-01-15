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

    private init() {}

    func addToolBarTrailingView() -> AnyView? {
        AnyView(BtnOpenCursorView.shared)
    }
}

// MARK: - PluginRegistrant

extension OpenCursorPlugin {
    @objc static func register() {
        // 检查用户是否禁用了此插件
        guard PluginSettingsStore.shared.isPluginEnabled("OpenCursor") else {
            if Self.verbose {
                os_log("\(Self.t)⚠️ OpenCursorPlugin is disabled by user settings")
            }
            return
        }

        // 检查 Cursor 是否安装
        guard isCursorInstalled() else {
            if Self.verbose {
                os_log("\(Self.t)⚠️ Cursor is not installed, skipping OpenCursorPlugin registration")
            }
            return
        }

        Task {
            if Self.verbose {
                os_log("\(Self.t)🚀 Register OpenCursorPlugin")
            }

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
            if Self.verbose {
                os_log("\(Self.t)✅ Found Cursor at: \(appURL.path)")
            }
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
                if Self.verbose {
                    os_log("\(Self.t)✅ Found Cursor at: \(path)")
                }
                return true
            }
        }

        if Self.verbose {
            os_log("\(Self.t)❌ Cursor not found in system")
        }

        return false
    }
}
