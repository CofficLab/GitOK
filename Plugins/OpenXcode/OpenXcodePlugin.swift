import Cocoa
import MagicKit
import OSLog
import SwiftUI

/// 打开 Xcode 插件
/// 提供在工具栏中打开当前项目 Xcode 的功能
class OpenXcodePlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = OpenXcodePlugin()
    /// 日志标识符
    nonisolated static let emoji = "🛠️"

    /// 是否启用该插件
    static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    static var label: String = "OpenXcode"

    /// 插件的唯一标识符，用于设置管理
    static var id: String = "OpenXcode"

    /// 插件显示名称
    static var displayName: String = "OpenXcode"

    /// 插件描述
    static var description: String = "在 Xcode 中打开当前项目"

    /// 插件图标名称
    static var iconName: String = "hammer"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var isConfigurable: Bool = true

    private init() {}

    func addToolBarTrailingView() -> AnyView? {
        return AnyView(BtnOpenXcodeView.shared)
    }
}

// MARK: - PluginRegistrant

extension OpenXcodePlugin {
    @objc static func register() {
        guard enable else { return }


        // 检查 Xcode 是否安装
        guard isXcodeInstalled() else {
            if Self.verbose {
                os_log("\(Self.t)⚠️ Xcode is not installed, skipping OpenXcodePlugin registration")
            }
            return
        }

        Task {
            if Self.verbose {
                os_log("\(Self.t)🚀 Register OpenXcodePlugin")
            }

            await PluginRegistry.shared.register(id: "OpenXcode", order: 11) {
                OpenXcodePlugin.shared
            }
        }
    }

    /// 检查 Xcode 是否已安装
    /// - Returns: 如果 Xcode 已安装返回 true，否则返回 false
    private static func isXcodeInstalled() -> Bool {
        // 方法1: 通过 Bundle Identifier 检查（Xcode 和 Xcode Beta）
        let bundleIds = [
            "com.apple.dt.Xcode",
            "com.apple.dt.Xcode.beta"
        ]

        for bundleId in bundleIds {
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
                if Self.verbose {
                    os_log("\(Self.t)✅ Found Xcode at: \(appURL.path)")
                }
                return true
            }
        }

        // 方法2: 通过应用路径检查（作为备选）
        let applicationPaths = [
            "/Applications/Xcode.app",
            "/Applications/Xcode-beta.app",
            NSHomeDirectory() + "/Applications/Xcode.app",
            NSHomeDirectory() + "/Applications/Xcode-beta.app"
        ]

        for path in applicationPaths {
            if FileManager.default.fileExists(atPath: path) {
                if Self.verbose {
                    os_log("\(Self.t)✅ Found Xcode at: \(path)")
                }
                return true
            }
        }

        if Self.verbose {
            os_log("\(Self.t)❌ Xcode not found in system")
        }

        return false
    }
}
