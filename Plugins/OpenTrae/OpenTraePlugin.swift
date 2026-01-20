import Cocoa
import MagicKit
import OSLog
import SwiftUI

class OpenTraePlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = OpenTraePlugin()
    /// 日志标识符
    nonisolated static let emoji = "🤖"

    /// 是否启用该插件
    static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    static var label: String = "OpenTrae"

    /// 插件的唯一标识符，用于设置管理
    static var id: String = "OpenTrae"

    /// 插件显示名称
    static var displayName: String = "OpenTrae"

    /// 插件描述
    static var description: String = "在 Trae 中打开当前项目"

    /// 插件图标名称
    static var iconName: String = "brain"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var isConfigurable: Bool = true

    private init() {}

    func addToolBarTrailingView() -> AnyView? {
        return AnyView(BtnOpenTraeView.shared)
    }
}

// MARK: - PluginRegistrant

extension OpenTraePlugin {
    @objc static func register() {
        guard enable else { return }


        // 检查 Trae 是否安装
        guard isTraeInstalled() else {
            if Self.verbose {
                os_log("\(Self.t)⚠️ Trae is not installed, skipping OpenTraePlugin registration")
            }
            return
        }

        Task {
            if Self.verbose {
                os_log("\(Self.t)🚀 Register OpenTraePlugin")
            }

            await PluginRegistry.shared.register(id: "OpenTrae", order: 13) {
                OpenTraePlugin.shared
            }
        }
    }

    /// 检查 Trae 是否已安装
    /// - Returns: 如果 Trae 已安装返回 true，否则返回 false
    private static func isTraeInstalled() -> Bool {
        // 方法1: 通过 Bundle Identifier 检查
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.abuilder.trae") {
            if Self.verbose {
                os_log("\(Self.t)✅ Found Trae at: \(appURL.path)")
            }
            return true
        }

        // 方法2: 通过应用路径检查（作为备选）
        let applicationPaths = [
            "/Applications/Trae.app",
            "/Applications/Trae.app/Contents/MacOS/Trae",
            NSHomeDirectory() + "/Applications/Trae.app"
        ]

        for path in applicationPaths {
            if FileManager.default.fileExists(atPath: path) {
                if Self.verbose {
                    os_log("\(Self.t)✅ Found Trae at: \(path)")
                }
                return true
            }
        }

        if Self.verbose {
            os_log("\(Self.t)❌ Trae not found in system")
        }

        return false
    }
}
