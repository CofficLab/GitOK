import Cocoa
import MagicKit
import OSLog
import SwiftUI

class OpenVSCodePlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = OpenVSCodePlugin()
    /// 日志标识符
    nonisolated static let emoji = "💻"

    /// 是否启用该插件
    static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    static var label: String = "OpenVSCode"

    /// 插件的唯一标识符，用于设置管理
    static var id: String = "OpenVSCode"

    /// 插件显示名称
    static var displayName: String = "OpenVSCode"

    /// 插件描述
    static var description: String = "在 VS Code 中打开当前项目"

    /// 插件图标名称
    static var iconName: String = "code"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var isConfigurable: Bool = true

    private init() {}

    func addToolBarTrailingView() -> AnyView? {
        // 检查用户是否启用了此插件
        guard PluginSettingsStore.shared.isPluginEnabled("OpenVSCode") else {
            return nil
        }

        return AnyView(BtnOpenVSCodeView.shared)
    }
}

// MARK: - PluginRegistrant

extension OpenVSCodePlugin {
    @objc static func register() {
        guard enable else { return }


        // 检查 VSCode 是否安装
        guard isVSCodeInstalled() else {
            if Self.verbose {
                os_log("\(Self.t)⚠️ VSCode is not installed, skipping OpenVSCodePlugin registration")
            }
            return
        }

        Task {
            if Self.verbose {
                os_log("\(Self.t)🚀 Register OpenVSCodePlugin")
            }

            await PluginRegistry.shared.register(id: "OpenVSCode", order: 12) {
                OpenVSCodePlugin.shared
            }
        }
    }

    /// 检查 VSCode 是否已安装
    /// - Returns: 如果 VSCode 已安装返回 true，否则返回 false
    private static func isVSCodeInstalled() -> Bool {
        // 方法1: 通过 Bundle Identifier 检查（VSCode 和 VSCode Insiders）
        let bundleIds = [
            "com.microsoft.VSCode",
            "com.microsoft.VSCodeInsiders"
        ]

        for bundleId in bundleIds {
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
                if Self.verbose {
                    os_log("\(Self.t)✅ Found VSCode at: \(appURL.path)")
                }
                return true
            }
        }

        // 方法2: 通过应用路径检查（作为备选）
        let applicationPaths = [
            "/Applications/Visual Studio Code.app",
            "/Applications/Visual Studio Code Insiders.app",
            "/Applications/VSCode.app",
            NSHomeDirectory() + "/Applications/Visual Studio Code.app",
            NSHomeDirectory() + "/Applications/VSCode.app"
        ]

        for path in applicationPaths {
            if FileManager.default.fileExists(atPath: path) {
                if Self.verbose {
                    os_log("\(Self.t)✅ Found VSCode at: \(path)")
                }
                return true
            }
        }

        if Self.verbose {
            os_log("\(Self.t)❌ VSCode not found in system")
        }

        return false
    }
}
