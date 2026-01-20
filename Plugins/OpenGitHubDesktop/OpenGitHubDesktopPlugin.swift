import Cocoa
import MagicKit
import OSLog
import SwiftUI

/// 打开 GitHub Desktop 插件
/// 在工具栏中提供用 GitHub Desktop 打开当前项目的功能
class OpenGitHubDesktopPlugin: SuperPlugin, SuperLog, PluginRegistrant {
    static let shared = OpenGitHubDesktopPlugin()
    /// 日志标识符
    nonisolated static let emoji = "🐱"

    /// 是否启用该插件
    static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    static var label: String = "OpenGitHubDesktop"

    /// 插件的唯一标识符，用于设置管理
    static var id: String = "OpenGitHubDesktop"

    /// 插件显示名称
    static var displayName: String = "OpenGitHubDesktop"

    /// 插件描述
    static var description: String = "在 GitHub Desktop 中打开当前项目"

    /// 插件图标名称（用于设置页展示）
    static var iconName: String = "desktopcomputer"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var isConfigurable: Bool = true

    private init() {}

    /// 在工具栏右侧添加视图
    /// - Returns: 打开 GitHub Desktop 的按钮视图
    func addToolBarTrailingView() -> AnyView? {
        // 检查用户是否启用了此插件
        guard PluginSettingsStore.shared.isPluginEnabled(Self.id) else {
            return nil
        }
        return AnyView(BtnOpenGitHubDesktopView.shared)
    }
}

// MARK: - PluginRegistrant

extension OpenGitHubDesktopPlugin {
    /// 自动注册插件到插件注册表（当系统检测到安装后）
    @objc static func register() {

        // 检查 GitHub Desktop 是否安装
        guard isGitHubDesktopInstalled() else {
                os_log("\(Self.t)⚠️ GitHub Desktop 未安装，跳过注册")
            return
        }

        Task {
            // 排序为 17，位于 OpenRemote(16) 之后
            await PluginRegistry.shared.register(id: Self.id, order: 17) {
                OpenGitHubDesktopPlugin.shared
            }
        }
    }

    /// 检查 GitHub Desktop 是否已安装
    /// - Returns: 如果已安装返回 true，否则返回 false
    private static func isGitHubDesktopInstalled() -> Bool {
        // 方法1: 通过 Bundle Identifier 检查
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.github.GitHubClient") {
                os_log("\(Self.t)✅ Found GitHub Desktop at: \(appURL.path)")
            return true
        }

        // 方法2: 通过应用路径检查（作为备选）
        let applicationPaths = [
            "/Applications/GitHub Desktop.app",
            NSHomeDirectory() + "/Applications/GitHub Desktop.app"
        ]

        for path in applicationPaths {
            if FileManager.default.fileExists(atPath: path) {
                    os_log("\(Self.t)✅ Found GitHub Desktop at: \(path)")
                return true
            }
        }

            os_log("\(Self.t)❌ GitHub Desktop not found in system")

        return false
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
