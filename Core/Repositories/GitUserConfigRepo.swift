import Foundation
import MagicKit
import SwiftData
import OSLog
import SwiftUI

/// Git 用户配置模型
/// 存储用户的 Git 姓名和邮箱信息
@Model
final class GitUserConfig: SuperLog {
    /// 日志标识符
    nonisolated static let emoji = "👤"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 用户姓名
    var name: String

    /// 用户邮箱
    var email: String

    /// 创建时间戳
    var timestamp: Date

    /// 是否为默认配置
    var isDefault: Bool
    
    var title: String {
        name.isEmpty ? email : name
    }
    
    init(name: String, email: String, isDefault: Bool = false) {
        self.name = name
        self.email = email
        self.isDefault = isDefault
        self.timestamp = .now
    }
}

extension GitUserConfig: Identifiable {
    var id: String {
        "\(name)_\(email)"
    }
}

class GitUserConfigRepo: BaseRepositoryImpl<GitUserConfig>, GitUserConfigRepoProtocol {
    
    // MARK: - 基础CRUD操作
    
    func create(name: String, email: String, isDefault: Bool = false) throws -> GitUserConfig {
        // 检查是否已存在相同的配置
        if let existing = try? findByNameAndEmail(name, email) {
            logger.info("⚠️ User config already exists: \(name) <\(email)>")
            return existing
        }
        
        let config = GitUserConfig(name: name, email: email, isDefault: isDefault)
        modelContext.insert(config)
        
        // 如果设置为默认，清除其他默认配置
        if isDefault {
            try clearAllDefaultsExcept(config)
        }
        
        try save()
        logger.info("➕ Created user config: \(name) <\(email)>")
        return config
    }
    
    func findByNameAndEmail(_ name: String, _ email: String) throws -> GitUserConfig? {
        let descriptor = FetchDescriptor<GitUserConfig>(
            predicate: #Predicate<GitUserConfig> { config in
                config.name == name && config.email == email
            }
        )
        return try fetch(descriptor).first
    }
    
    func findDefault() throws -> GitUserConfig? {
        let descriptor = FetchDescriptor<GitUserConfig>(
            predicate: #Predicate<GitUserConfig> { config in
                config.isDefault == true
            }
        )
        return try fetch(descriptor).first
    }
    
    func update(_ config: GitUserConfig) throws {
        try save()
        logger.info("📝 Updated user config: \(config.name) <\(config.email)>")
    }
    
    // MARK: - 查询操作
    
    func findAll(sortedBy order: SortOrder = .ascending) throws -> [GitUserConfig] {
        let timestampSort = SortDescriptor<GitUserConfig>(
            \.timestamp,
            order: order == .ascending ? .forward : .reverse
        )
        let descriptor = FetchDescriptor<GitUserConfig>(
            sortBy: [timestampSort]
        )
        return try fetch(descriptor)
    }
    
    func findByName(_ name: String) throws -> [GitUserConfig] {
        let descriptor = FetchDescriptor<GitUserConfig>(
            predicate: #Predicate<GitUserConfig> { config in
                config.name.localizedStandardContains(name)
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try fetch(descriptor)
    }
    
    func findByEmail(_ email: String) throws -> [GitUserConfig] {
        let descriptor = FetchDescriptor<GitUserConfig>(
            predicate: #Predicate<GitUserConfig> { config in
                config.email.localizedStandardContains(email)
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try fetch(descriptor)
    }
    
    // MARK: - 业务操作
    
    func exists(name: String, email: String) -> Bool {
        do {
            return try findByNameAndEmail(name, email) != nil
        } catch {
            logger.error("❌ Error checking user config existence: \(error.localizedDescription)")
            return false
        }
    }
    
    func setAsDefault(_ config: GitUserConfig) throws {
        // 清除所有默认设置
        try clearAllDefaults()
        
        // 设置指定配置为默认
        config.isDefault = true
        try update(config)
        logger.info("⭐ Set as default: \(config.name) <\(config.email)>")
    }
    
    func clearAllDefaults() throws {
        let allConfigs = try fetchAll()
        for config in allConfigs {
            if config.isDefault {
                config.isDefault = false
            }
        }
        try save()
        logger.info("🗑️ Cleared all default settings")
    }
    
    private func clearAllDefaultsExcept(_ exception: GitUserConfig) throws {
        let allConfigs = try fetchAll()
        for config in allConfigs {
            if config != exception && config.isDefault {
                config.isDefault = false
            }
        }
    }
    
    func getConfigCount() throws -> Int {
        return try fetchAll().count
    }
    
    func getRecentConfigs(limit: Int = 5) throws -> [GitUserConfig] {
        var descriptor = FetchDescriptor<GitUserConfig>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try fetch(descriptor)
    }
    
    // MARK: - 高级查询
    
    func findConfigsUsedAfter(_ date: Date) throws -> [GitUserConfig] {
        let descriptor = FetchDescriptor<GitUserConfig>(
            predicate: #Predicate<GitUserConfig> { config in
                config.timestamp > date
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try fetch(descriptor)
    }
    
    func searchConfigs(query: String) throws -> [GitUserConfig] {
        let descriptor = FetchDescriptor<GitUserConfig>(
            predicate: #Predicate<GitUserConfig> { config in
                config.name.localizedStandardContains(query) ||
                config.email.localizedStandardContains(query)
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try fetch(descriptor)
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .hideTabPicker()
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}
