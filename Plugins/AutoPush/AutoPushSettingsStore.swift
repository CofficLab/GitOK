import Foundation
import Combine
import MagicKit
import OSLog

/// 自动推送配置存储：管理每个项目每个分支的自动推送设置
class AutoPushSettingsStore: ObservableObject, SuperLog {
    static let shared = AutoPushSettingsStore()
    
    nonisolated static let emoji = "💾"

    private let userDefaultsKey = "GitOK_AutoPushSettings"
    
    /// 本地 verbose 标志，避免访问 @MainActor 隔离的属性
    private let verbose = AutoPushService.verbose

    /// 发布设置变化，让订阅者能够实时响应
    @Published private(set) var settings: [String: ProjectBranchAutoPushConfig] = [:]

    private init() {
        // 初始化时从 UserDefaults 加载设置
        self.settings = loadSettings()
        
        if verbose {
            os_log(.info, "%{public}@ loaded %d settings", Self.t, settings.count)
        }
    }

    /// 生成项目分支的唯一键
    /// - Parameters:
    ///   - projectPath: 项目路径
    ///   - branchName: 分支名称
    /// - Returns: 唯一标识键
    private func makeKey(projectPath: String, branchName: String) -> String {
        return "\(projectPath)://\(branchName)"
    }

    /// 解析配置键
    /// - Parameter key: 配置键
    /// - Returns: 项目路径和分支名称的元组
    private func parseKey(_ key: String) -> (projectPath: String, branchName: String)? {
        let components = key.components(separatedBy: "://")
        guard components.count == 2 else { return nil }
        return (projectPath: components[0], branchName: components[1])
    }

    /// 获取指定项目分支的自动推送配置
    /// - Parameters:
    ///   - projectPath: 项目路径
    ///   - branchName: 分支名称
    /// - Returns: 自动推送配置，如果不存在则返回 nil
    func getConfig(for projectPath: String, branchName: String) -> ProjectBranchAutoPushConfig? {
        let key = makeKey(projectPath: projectPath, branchName: branchName)
        return settings[key]
    }

    /// 检查指定项目分支是否启用了自动推送
    /// - Parameters:
    ///   - projectPath: 项目路径
    ///   - branchName: 分支名称
    /// - Returns: true 表示启用了自动推送
    func isAutoPushEnabled(for projectPath: String, branchName: String) -> Bool {
        let key = makeKey(projectPath: projectPath, branchName: branchName)
        let enabled = settings[key]?.isEnabled == true
        if verbose {
            os_log(.info, "%{public}@ isAutoPushEnabled for %{public}@/%{public}@: %{public}@", 
                   Self.t, projectPath, branchName, enabled ? "true" : "false")
        }
        return enabled
    }

    /// 设置指定项目分支的自动推送状态
    /// - Parameters:
    ///   - projectPath: 项目路径
    ///   - branchName: 分支名称
    ///   - enabled: true 表示启用，false 表示禁用
    func setAutoPushEnabled(for projectPath: String, branchName: String, enabled: Bool) {
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
        
        // 强制触发 @Published 通知
        objectWillChange.send()
        
        saveSettings()
        
        if verbose {
            os_log(.info, "%{public}@ set %{public}@/%{public}@ = %{public}@", 
                   Self.t, projectPath, branchName, enabled ? "true" : "false")
            os_log(.info, "%{public}@ saved %d settings", Self.t, settings.count)
        }
    }

    /// 更新最后推送时间
    /// - Parameters:
    ///   - projectPath: 项目路径
    ///   - branchName: 分支名称
    func updateLastPushedDate(for projectPath: String, branchName: String) {
        let key = makeKey(projectPath: projectPath, branchName: branchName)
        
        if var config = settings[key] {
            config.lastPushedAt = Date()
            settings[key] = config
            
            // 强制触发 @Published 通知
            objectWillChange.send()
            
            saveSettings()
        }
    }

    /// 获取指定项目的所有自动推送配置
    /// - Parameter projectPath: 项目路径
    /// - Returns: 该项目的自动推送配置列表
    func getConfigs(forProject projectPath: String) -> [ProjectBranchAutoPushConfig] {
        return settings.values.filter { $0.projectPath == projectPath }
    }

    /// 删除指定项目分支的配置
    /// - Parameters:
    ///   - projectPath: 项目路径
    ///   - branchName: 分支名称
    func removeConfig(for projectPath: String, branchName: String) {
        let key = makeKey(projectPath: projectPath, branchName: branchName)
        settings.removeValue(forKey: key)
        
        // 强制触发 @Published 通知
        objectWillChange.send()
        
        saveSettings()
    }

    /// 删除指定项目的所有配置
    /// - Parameter projectPath: 项目路径
    func removeConfigs(forProject projectPath: String) {
        let keysToRemove = settings.keys.filter { key in
            guard let parsed = parseKey(key) else { return false }
            return parsed.projectPath == projectPath
        }
        
        for key in keysToRemove {
            settings.removeValue(forKey: key)
        }
        
        // 强制触发 @Published 通知
        objectWillChange.send()
        
        saveSettings()
    }

    /// 获取所有启用自动推送的配置
    /// - Returns: 所有启用的自动推送配置列表
    func getAllEnabledConfigs() -> [ProjectBranchAutoPushConfig] {
        return settings.values.filter { $0.isEnabled }
    }

    /// 加载所有自动推送设置
    private func loadSettings() -> [String: ProjectBranchAutoPushConfig] {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([String: ProjectBranchAutoPushConfig].self, from: data) else {
            if verbose {
                os_log(.info, "%{public}@ no settings found in UserDefaults", Self.t)
            }
            return [:]
        }
        
        if verbose {
            os_log(.info, "%{public}@ loaded %d settings from UserDefaults", Self.t, decoded.count)
            for (key, config) in decoded {
                os_log(.info, "  - %{public}@: enabled=%{public}@", key, config.isEnabled ? "true" : "false")
            }
        }
        
        return decoded
    }

    /// 保存自动推送设置
    func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            UserDefaults.standard.synchronize() // 强制立即写入磁盘
            
            if verbose {
                os_log(.info, "%{public}@ saved %d settings to UserDefaults", Self.t, settings.count)
                
                // 验证保存的数据
                if let savedData = UserDefaults.standard.data(forKey: userDefaultsKey),
                   let savedSettings = try? JSONDecoder().decode([String: ProjectBranchAutoPushConfig].self, from: savedData) {
                    os_log(.info, "%{public}@ verified: %d settings saved successfully", Self.t, savedSettings.count)
                }
            }
        } else {
            os_log(.error, "%{public}@ failed to encode settings", Self.t)
        }
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
