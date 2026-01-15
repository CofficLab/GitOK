import Cocoa
import MagicKit
import OSLog
import SwiftUI

class OpenAntigravityPlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = OpenAntigravityPlugin()
    /// 日志标识符
    nonisolated static let emoji = "🌌"

    /// 是否启用该插件
    static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    static var label: String = "OpenAntigravity"

    private init() {}

    func addToolBarTrailingView() -> AnyView? {
        AnyView(BtnOpenAntigravityView.shared)
    }
}

// MARK: - PluginRegistrant

extension OpenAntigravityPlugin {
    @objc static func register() {
        guard enable else { return }

        // 检查 Antigravity 是否安装
        guard isAntigravityInstalled() else {
            if Self.verbose {
                os_log("\(Self.t)⚠️ Antigravity is not installed, skipping OpenAntigravityPlugin registration")
            }
            return
        }

        Task {
            if Self.verbose {
                os_log("\(Self.t)🚀 Register OpenAntigravityPlugin")
            }

            await PluginRegistry.shared.register(id: "OpenAntigravity", order: 14) {
                OpenAntigravityPlugin.shared
            }
        }
    }

    /// 检查 Antigravity 是否已安装
    /// - Returns: 如果 Antigravity 已安装返回 true，否则返回 false
    private static func isAntigravityInstalled() -> Bool {
        // 方法1: 通过 Bundle Identifier 检查
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.antigravity.app") {
            if Self.verbose {
                os_log("\(Self.t)✅ Found Antigravity at: \(appURL.path)")
            }
            return true
        }

        // 方法2: 通过应用路径检查（作为备选）
        let applicationPaths = [
            "/Applications/Antigravity.app",
            NSHomeDirectory() + "/Applications/Antigravity.app"
        ]

        for path in applicationPaths {
            if FileManager.default.fileExists(atPath: path) {
                if Self.verbose {
                    os_log("\(Self.t)✅ Found Antigravity at: \(path)")
                }
                return true
            }
        }

        if Self.verbose {
            os_log("\(Self.t)❌ Antigravity not found in system")
        }

        return false
    }
}
