import Foundation
import MagicCore
import OSLog
import SwiftUI

/**
 * 统一图标仓库管理器
 * 作为门面整合多个图标来源，提供统一的接口
 * 支持动态添加和管理图标来源，通过协议实现解耦
 * 支持本地优先、远程补充的数据获取策略
 */
class IconRepo: SuperLog {
    nonisolated static var emoji: String { "🔗" }

    /// 单例实例
    static let shared = IconRepo()

    /// 图标来源列表
    private var iconSources: [IconSourceProtocol] = []

    /// 私有初始化方法，确保单例模式
    private init() {
        // 初始化默认图标来源
        setupDefaultSources()
    }
    
    /// 设置默认图标来源
    private func setupDefaultSources() {
        // 添加本地图标来源
        addIconSource(AppIconRepo.shared)
        
        // 添加远程图标来源
        addIconSource(WebIconRepo.shared)
    }
    
    // MARK: - 图标来源管理
    
    /// 添加图标来源
    /// - Parameter source: 图标来源实例
    func addIconSource(_ source: IconSourceProtocol) {
        // 避免重复添加相同类型和标识的来源
        if !iconSources.contains(where: { existingSource in
            existingSource.sourceType == source.sourceType && 
            existingSource.sourceName == source.sourceName
        }) {
            iconSources.append(source)
            os_log(.info, "\(self.t)添加图标来源：\(source.sourceName)")
        }
    }
    
    /// 移除图标来源
    /// - Parameter sourceType: 来源类型
    /// - Parameter sourceName: 来源名称
    func removeIconSource(type: IconSourceType, name: String) {
        iconSources.removeAll { source in
            source.sourceType == type && source.sourceName == name
        }
        os_log(.info, "\(self.t)移除图标来源：\(name)")
    }
    
    /// 获取所有可用的图标来源
    /// - Returns: 图标来源数组
    func getAllIconSources() -> [IconSourceProtocol] {
        return iconSources
    }
    
    /// 获取指定类型的图标来源
    /// - Parameter sourceType: 来源类型
    /// - Returns: 匹配的图标来源数组
    func getIconSources(byType sourceType: IconSourceType) -> [IconSourceProtocol] {
        return iconSources.filter { $0.sourceType == sourceType }
    }
    
    // MARK: - 核心业务接口
    
    /// 获取所有可用的图标分类
    /// - Parameter enableRemote: 是否启用远程分类，默认启用
    /// - Returns: IconCategoryInfo 数组
    func getAllCategories(enableRemote: Bool = true) async -> [IconCategoryInfo] {
        var allCategories: [IconCategoryInfo] = []
        
        for source in iconSources {
            // 根据设置过滤远程来源
            if !enableRemote && source.sourceType == .remote {
                continue
            }
            
            // 检查来源是否可用
            if await source.isAvailable {
                let categories = await source.getAllCategories()
                allCategories.append(contentsOf: categories)
            }
        }
        
        // 去重（基于 id + sourceType + sourceIdentifier）
        var uniqueCategories: [IconCategoryInfo] = []
        var seenKeys: Set<String> = []
        
        for category in allCategories {
            let key = "\(category.id)_\(category.sourceType)_\(category.sourceIdentifier)"
            if !seenKeys.contains(key) {
                seenKeys.insert(key)
                uniqueCategories.append(category)
            }
        }
        
        // 按名称排序
        return uniqueCategories.sorted { $0.name < $1.name }
    }

    /// 获取指定分类的图标列表
    /// - Parameter categoryInfo: 分类信息
    /// - Returns: IconAsset 数组
    func getIcons(for categoryInfo: IconCategoryInfo) async -> [IconAsset] {
        // 找到对应的图标来源
        let matchingSources = iconSources.filter { source in
            source.sourceType == categoryInfo.sourceType
        }
        
        for source in matchingSources {
            if await source.isAvailable {
                let icons = await source.getIcons(for: categoryInfo.id)
                if !icons.isEmpty {
                    return icons
                }
            }
        }
        
        return []
    }

    /// 获取指定名称的分类
    /// - Parameter name: 分类名称
    /// - Returns: IconCategoryInfo 实例，如果不存在则返回nil
    func getCategory(byName name: String) async -> IconCategoryInfo? {
        let allCategories = await getAllCategories()
        return allCategories.first { $0.name == name }
    }
    
    /// 根据图标ID获取图标
    /// - Parameter iconId: 图标ID
    /// - Returns: IconAsset实例，如果找不到则返回nil
    func getIconAsset(byId iconId: String) async -> IconAsset? {
        // 遍历所有可用的图标来源
        for source in iconSources {
            if await source.isAvailable {
                if let icon = await source.getIconAsset(byId: iconId) {
                    return icon
                }
            }
        }
        
        return nil
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(IconPlugin.label)
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 800)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(IconPlugin.label)
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
