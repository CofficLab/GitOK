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
        
        // 添加项目图标来源
        addIconSource(ProjectImagesRepo.shared)
    }
    
    // MARK: - 图标来源管理
    
    /// 添加图标来源
    /// - Parameter source: 图标来源实例
    func addIconSource(_ source: IconSourceProtocol) {
        // 避免重复添加相同标识的来源
        if !iconSources.contains(where: { existingSource in
            existingSource.sourceIdentifier == source.sourceIdentifier
        }) {
            iconSources.append(source)
            os_log(.info, "\(self.t)添加图标来源：\(source.sourceName)")
        }
    }
    
    /// 移除图标来源
    /// - Parameter sourceIdentifier: 来源唯一标识
    func removeIconSource(identifier sourceIdentifier: String) {
        iconSources.removeAll { source in
            source.sourceIdentifier == sourceIdentifier
        }
        os_log(.info, "\(self.t)移除图标来源：\(sourceIdentifier)")
    }
    
    /// 获取所有可用的图标来源
    /// - Returns: 图标来源数组
    func getAllIconSources() -> [IconSourceProtocol] {
        return iconSources
    }
    
    // MARK: - 核心业务接口
    
    /// 获取所有可用的图标分类
    /// - Parameter enableRemote: 是否启用远程分类，默认启用（保留开关向后兼容）
    /// - Returns: IconCategoryInfo 数组
    func getAllCategories(enableRemote: Bool = true) async -> [IconCategoryInfo] {
        var allCategories: [IconCategoryInfo] = []
        print("[IconRepo] getAllCategories from sources: \(iconSources.count)")
        
        for source in iconSources {
            print("[IconRepo] pulling from source: \(source.sourceName) [id=\(source.sourceIdentifier)]")
            let categories = await source.getAllCategories()
            print("[IconRepo] source returned: \(categories.count) categories")
            allCategories.append(contentsOf: categories)
        }
        
        var uniqueCategories: [IconCategoryInfo] = []
        var seenKeys: Set<String> = []
        
        for category in allCategories {
            let key = "\(category.id)_\(category.sourceIdentifier)"
            if !seenKeys.contains(key) {
                seenKeys.insert(key)
                uniqueCategories.append(category)
            }
        }
        print("[IconRepo] unique categories: \(uniqueCategories.count)")
        
        return uniqueCategories.sorted { $0.name < $1.name }
    }

    /// 获取指定分类的图标列表
    /// - Parameter categoryInfo: 分类信息
    /// - Returns: IconAsset 数组
    func getIcons(for categoryInfo: IconCategoryInfo) async -> [IconAsset] {
        // 找到对应的图标来源（按 sourceIdentifier 精确匹配）
        guard let source = iconSources.first(where: { $0.sourceIdentifier == categoryInfo.sourceIdentifier }) else {
            return []
        }
        
        if await source.isAvailable {
            return await source.getIcons(for: categoryInfo.id)
        }
        return []
    }

    /// 获取指定来源的所有图标（用于不支持分类的来源）
    /// - Parameter sourceIdentifier: 来源标识
    /// - Returns: 该来源下的所有图标
    func getAllIcons(for sourceIdentifier: String) async -> [IconAsset] {
        guard let source = iconSources.first(where: { $0.sourceIdentifier == sourceIdentifier }) else {
            return []
        }
        if await source.isAvailable {
            return await source.getAllIcons()
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
    /// - Returns: 图标Asset实例，如果找不到则返回nil
    func getIconAsset(byId iconId: String) async -> IconAsset? {
        return await withTaskGroup(of: IconAsset?.self, returning: IconAsset?.self) { group in
            for source in iconSources {
                group.addTask {
                    if await source.isAvailable {
                        return await source.getIconAsset(byId: iconId)
                    }
                    return nil
                }
            }

            for await result in group {
                if let icon = result {
                    group.cancelAll()
                    return icon
                }
            }
            return nil
        }
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
    .frame(width: 800)
    .frame(height: 1200)
}
