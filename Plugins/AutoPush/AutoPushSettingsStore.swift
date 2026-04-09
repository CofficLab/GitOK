import Foundation
import Combine
import MagicKit
import OSLog

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
    
    nonisolated static let emoji = "💾"
    nonisolated static let verbose = true

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
            os_log(.info, "%{public}@ initialized with %d settings", Self.t, settings.count)
        }
    }

    /// 生成项目分支的唯一键
    private func makeKey(projectPath: String, branchName: String) -> String {
        return "\(projectPath)://\(branchName)"
    }

    /// 解析配置键
    private func parseKey(_ key: String) -> (projectPath: String, branchName: String)? {
        let components = key.components(separatedBy: "://")
        guard components.count == 2 else { return nil }
        return (projectPath: components[0], branchName: components[1])
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
                os_log(.info, "%{public}@ isAutoPushEnabled for %{public}@/%{public}@: %{public}@", 
                       Self.t, projectPath, branchName, enabled ? "true" : "false")
            }
            return enabled
        }
    }

    /// 设置指定项目分支的自动推送状态
    func setAutoPushEnabled(for projectPath: String, branchName: String, enabled: Bool) {
        queue.sync {
            let key = makeKey(projectPath: projectPath, branchName: branchName)
            
            if var config = settings[key] {
                config.isEnabled = enabled
                config.lastModified = Date()
                settings[key] = config
            } else {
                let config = ProjectBranchAutoPushConfig(
                    projectPath: projectPath,
                    branchName: branchName,
                    isEnabled: enabled,
                    lastModified: Date()
                )
                settings[key] = config
            }
            
            // 触发 SwiftUI 观察更新
            objectWillChange.send()
            
            // 持久化到文件
            persistSettingsToCurrentFile(settings: settings)
            
            if Self.verbose {
                os_log(.info, "%{public}@ set %{public}@/%{public}@ = %{public}@", 
                       Self.t, projectPath, branchName, enabled ? "true" : "false")
                os_log(.info, "%{public}@ saved %d settings", Self.t, settings.count)
            }
        }
    }

    /// 更新最后推送时间
    func updateLastPushedDate(for projectPath: String, branchName: String) {
        queue.sync {
            let key = makeKey(projectPath: projectPath, branchName: branchName)
            
            if var config = settings[key] {
                config.lastPushedAt = Date()
                settings[key] = config
                
                // 触发 SwiftUI 观察更新
                objectWillChange.send()
                
                // 持久化到文件
                persistSettingsToCurrentFile(settings: settings)
            }
        }
    }

    /// 获取指定项目的所有自动推送配置
    func getConfigs(forProject projectPath: String) -> [ProjectBranchAutoPushConfig] {
        queue.sync {
            return settings.values.filter { $0.projectPath == projectPath }
        }
    }

    /// 删除指定项目分支的配置
    func removeConfig(for projectPath: String, branchName: String) {
        queue.sync {
            let key = makeKey(projectPath: projectPath, branchName: branchName)
            settings.removeValue(forKey: key)
            
            // 触发 SwiftUI 观察更新
            objectWillChange.send()
            
            // 持久化到文件
            persistSettingsToCurrentFile(settings: settings)
        }
    }

    /// 删除指定项目的所有配置
    func removeConfigs(forProject projectPath: String) {
        queue.sync {
            let keysToRemove = settings.keys.filter { key in
                guard let parsed = parseKey(key) else { return false }
                return parsed.projectPath == projectPath
            }
            
            for key in keysToRemove {
                settings.removeValue(forKey: key)
            }
            
            // 触发 SwiftUI 观察更新
            objectWillChange.send()
            
            // 持久化到文件
            persistSettingsToCurrentFile(settings: settings)
        }
    }

    /// 获取所有启用自动推送的配置
    func getAllEnabledConfigs() -> [ProjectBranchAutoPushConfig] {
        queue.sync {
            return settings.values.filter { $0.isEnabled }
        }
    }

    // MARK: - 文件存储实现

    /// 从文件加载设置
    private func loadSettings() -> [String: ProjectBranchAutoPushConfig] {
        let fileURL = currentStateFileURL()
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            if Self.verbose {
                os_log(.info, "%{public}@ no settings file found, using defaults", Self.t)
            }
            return [:]
        }
        
        guard let data = try? Data(contentsOf: fileURL),
              let settings = try? JSONDecoder().decode([String: ProjectBranchAutoPushConfig].self, from: data) else {
            if Self.verbose {
                os_log(.error, "%{public}@ failed to decode settings file", Self.t)
            }
            return [:]
        }
        
        if Self.verbose {
            os_log(.info, "%{public}@ loaded %d settings from file", Self.t, settings.count)
        }
        
        return settings
    }

    /// 保存设置到文件（atomic write）
    private func persistSettingsToCurrentFile(settings: [String: ProjectBranchAutoPushConfig]) {
        let fileManager = FileManager.default
        let settingsDir = currentSettingsDirURL()
        
        // 确保目录存在
        try? fileManager.createDirectory(at: settingsDir, withIntermediateDirectories: true, attributes: nil)

        let fileURL = currentStateFileURL()
        let tmpURL = settingsDir.appendingPathComponent(Self.tmpFileName, isDirectory: false)

        guard let data = try? JSONEncoder().encode(settings) else {
            os_log(.error, "%{public}@ failed to encode settings", Self.t)
            return
        }

        do {
            // 写入临时文件（atomic）
            try data.write(to: tmpURL, options: .atomic)
            
            // 替换原文件
            if fileManager.fileExists(atPath: fileURL.path) {
                _ = try? fileManager.replaceItemAt(fileURL, withItemAt: tmpURL)
            } else {
                try fileManager.moveItem(at: tmpURL, to: fileURL)
            }
            
            if Self.verbose {
                os_log(.info, "%{public}@ saved %d settings to file", Self.t, settings.count)
            }
        } catch {
            // 失败时清理临时文件
            try? fileManager.removeItem(at: tmpURL)
            os_log(.error, "%{public}@ failed to save settings: %{public}@", Self.t, error.localizedDescription)
        }
    }

    // MARK: - 路径计算

    private func currentSettingsDirURL() -> URL {
        AppConfig.getDBFolderURL()
            .appendingPathComponent(Self.pluginDirName, isDirectory: true)
            .appendingPathComponent(Self.settingsDirName, isDirectory: true)
    }

    private func currentStateFileURL() -> URL {
        currentSettingsDirURL()
            .appendingPathComponent(Self.stateFileName, isDirectory: false)
    }
}

/// 项目分支自动推送配置模型
struct ProjectBranchAutoPushConfig: Codable, Identifiable, Equatable {
    let id: String
    let projectPath: String
    let branchName: String
    var isEnabled: Bool
    var lastModified: Date
    var lastPushedAt: Date?

    init(projectPath: String, branchName: String, isEnabled: Bool = false, lastModified: Date = Date(), lastPushedAt: Date? = nil) {
        self.id = "\(projectPath)://\(branchName)"
        self.projectPath = projectPath
        self.branchName = branchName
        self.isEnabled = isEnabled
        self.lastModified = lastModified
        self.lastPushedAt = lastPushedAt
    }

    var projectTitle: String {
        return URL(fileURLWithPath: projectPath).lastPathComponent
    }
}