import Foundation
import Combine
import MagicKit
import os

/// 自动推送配置存储：管理每个项目每个分支的自动推送设置
/// 
/// 数据存储规范（遵循 Lumi 插件最佳实践）：
/// - 存储位置: <ApplicationSupport>/GitOK/AutoPush/settings/
/// - 文件格式: JSON (使用 Codable)
/// - 写入策略: atomic write + 临时文件
/// - 线程安全: 使用 DispatchQueue 串行化访问
/// - SwiftUI 观察: 通过 @Published 属性发布变更
final class AutoPushSettingsStore: ObservableObject, SuperLog {
    static let shared = AutoPushSettingsStore()
    
    // MARK: - Logger & Config

    /// 日志标识 emoji
    nonisolated static let emoji = "💾"

    /// 是否启用详细日志
    nonisolated static let verbose = false

    // MARK: - 文件路径配置
    
    private static let pluginDirName = "AutoPush"
    private static let settingsDirName = "settings"
    private static let stateFileName = "auto_push_settings.json"
    private static let tmpFileName = "auto_push_settings.tmp"
    
    // MARK: - 线程安全
    
    private let queue = DispatchQueue(label: "AutoPushSettingsStore.queue", qos: .userInitiated)
    
    /// 发布设置变化，让订阅者能够实时响应
    /// 注意：此属性主要用于 SwiftUI 观察，实际数据存储在线程安全的 queue 中
    @Published private(set) var settings: [String: ProjectBranchAutoPushConfig] = [:]

    private init() {
        // 初始化时从文件加载设置
        self.settings = loadSettings()

        if Self.verbose {
            AutoPushPlugin.logger.info("\(Self.t)📦 初始化完成，加载了 \(self.settings.count) 个配置")
        }
    }

    /// 生成项目分支的唯一键
    private func makeKey(projectPath: String, branchName: String) -> String {
        return AutoPushSettingsPersistence.makeKey(projectPath: projectPath, branchName: branchName)
    }

    /// 解析配置键
    private func parseKey(_ key: String) -> (projectPath: String, branchName: String)? {
        AutoPushSettingsPersistence.parseKey(key)
    }

    // MARK: - 公共 API（线程安全）

    /// 获取指定项目分支的自动推送配置
    func getConfig(for projectPath: String, branchName: String) -> ProjectBranchAutoPushConfig? {
        queue.sync {
            let key = makeKey(projectPath: projectPath, branchName: branchName)
            return settings[key]
        }
    }

    /// 检查指定项目分支是否启用了自动推送
    func isAutoPushEnabled(for projectPath: String, branchName: String) -> Bool {
        queue.sync {
            let key = makeKey(projectPath: projectPath, branchName: branchName)
            let enabled = settings[key]?.isEnabled == true

            if Self.verbose {
                AutoPushPlugin.logger.info("\(Self.t)检查启用状态 \(projectPath)/\(branchName): \(enabled ? "✅ 启用" : "⛔️ 禁用")")
            }
            return enabled
        }
    }

    /// 设置指定项目分支的自动推送状态
    func setAutoPushEnabled(for projectPath: String, branchName: String, enabled: Bool) {
        queue.sync {
            settings = AutoPushSettingsPersistence.updatedSettings(
                settings: settings,
                projectPath: projectPath,
                branchName: branchName,
                enabled: enabled,
                now: Date()
            )
            
            // 触发 SwiftUI 观察更新
            objectWillChange.send()

            // 持久化到文件
            persistSettingsToCurrentFile(settings: settings)

            if Self.verbose {
                AutoPushPlugin.logger.info("\(Self.t)💾 设置自动推送状态 \(projectPath)/\(branchName): \(enabled ? "✅ 启用" : "⛔️ 禁用")")
                AutoPushPlugin.logger.info("\(Self.t)💾 已保存 \(self.settings.count) 个配置")
            }
        }
    }

    /// 更新最后推送时间
    func updateLastPushedDate(for projectPath: String, branchName: String) {
        queue.sync {
            settings = AutoPushSettingsPersistence.updatedLastPushedDate(
                settings: settings,
                projectPath: projectPath,
                branchName: branchName,
                now: Date()
            )

            // 触发 SwiftUI 观察更新
            objectWillChange.send()

            // 持久化到文件
            persistSettingsToCurrentFile(settings: settings)
        }
    }

    /// 获取指定项目的所有自动推送配置
    func getConfigs(forProject projectPath: String) -> [ProjectBranchAutoPushConfig] {
        queue.sync {
            return AutoPushSettingsPersistence.configs(forProject: projectPath, in: settings)
        }
    }

    /// 删除指定项目分支的配置
    func removeConfig(for projectPath: String, branchName: String) {
        queue.sync {
            settings = AutoPushSettingsPersistence.settingsByRemovingConfig(
                settings: settings,
                projectPath: projectPath,
                branchName: branchName
            )
            
            // 触发 SwiftUI 观察更新
            objectWillChange.send()
            
            // 持久化到文件
            persistSettingsToCurrentFile(settings: settings)
        }
    }

    /// 删除指定项目的所有配置
    func removeConfigs(forProject projectPath: String) {
        queue.sync {
            settings = AutoPushSettingsPersistence.settingsByRemovingProject(
                settings: settings,
                projectPath: projectPath
            )
            
            // 触发 SwiftUI 观察更新
            objectWillChange.send()
            
            // 持久化到文件
            persistSettingsToCurrentFile(settings: settings)
        }
    }

    /// 获取所有启用自动推送的配置
    func getAllEnabledConfigs() -> [ProjectBranchAutoPushConfig] {
        queue.sync {
            return AutoPushSettingsPersistence.enabledConfigs(in: settings)
        }
    }

    // MARK: - 文件存储实现

    /// 从文件加载设置
    private func loadSettings() -> [String: ProjectBranchAutoPushConfig] {
        let settings = AutoPushSettingsPersistence.loadSettings(from: currentStateFileURL())

        if Self.verbose {
            AutoPushPlugin.logger.info("\(Self.t)📂 从文件加载了 \(settings.count) 个配置")
        }

        return settings
    }

    /// 保存设置到文件（atomic write）
    private func persistSettingsToCurrentFile(settings: [String: ProjectBranchAutoPushConfig]) {
        AutoPushSettingsPersistence.persist(settings, to: currentStateFileURL())

        if Self.verbose {
            AutoPushPlugin.logger.info("\(Self.t)💾 已保存 \(settings.count) 个配置到文件")
        }
    }

    // MARK: - 路径计算

    private func currentSettingsDirURL() -> URL {
        AppConfig.getDBFolderURL()
            .appendingPathComponent(Self.pluginDirName, isDirectory: true)
            .appendingPathComponent(AutoPushSettingsPersistence.settingsDirName, isDirectory: true)
    }

    private func currentStateFileURL() -> URL {
        currentSettingsDirURL()
            .appendingPathComponent(AutoPushSettingsPersistence.stateFileName, isDirectory: false)
    }
}
