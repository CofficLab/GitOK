import Foundation
import SwiftUI
import OSLog
import MagicCore

/**
 * 统一图标仓库管理器
 * 作为门面整合本地和远程图标仓库，提供统一的接口
 * 支持本地优先、远程补充的数据获取策略
 */
class IconRepo: SuperLog {
    nonisolated static var emoji: String { "🔗" }
    
    /// 单例实例
    static let shared = IconRepo()
    
    /// 本地图标仓库
    private let localRepo = AppIconRepo.shared
    
    /// 远程图标仓库
    private let remoteRepo = RemoteIconRepo.shared
    
    /// 私有初始化方法，确保单例模式
    private init() {}
    
    /// 获取所有可用的图标分类（本地 + 远程）
    /// - Returns: 统一图标分类数组
    func getAllCategories() async -> [UnifiedIconCategory] {
        // 获取本地分类
        let localCategories = localRepo.getAllCategories()
        
        // 获取远程分类
        let remoteCategories = await remoteRepo.getAllCategories()
        
        // 合并分类，本地优先
        var unifiedCategories: [UnifiedIconCategory] = []
        
        // 添加本地分类
        for localCategory in localCategories {
            let unifiedCategory = UnifiedIconCategory(
                id: localCategory.id,
                name: localCategory.name,
                displayName: localCategory.displayName,
                iconCount: localCategory.iconCount,
                source: .local,
                localCategory: localCategory,
                remoteCategory: nil
            )
            unifiedCategories.append(unifiedCategory)
        }
        
        // 添加远程分类（避免重复）
        for remoteCategory in remoteCategories {
            if !unifiedCategories.contains(where: { $0.name == remoteCategory.name }) {
                let unifiedCategory = UnifiedIconCategory(
                    id: URL(string: "remote://\(remoteCategory.id)") ?? URL(string: "https://gitok.coffic.cn/\(remoteCategory.id)")!,
                    name: remoteCategory.name,
                    displayName: remoteCategory.displayName,
                    iconCount: remoteCategory.iconCount,
                    source: .remote,
                    localCategory: nil,
                    remoteCategory: remoteCategory
                )
                unifiedCategories.append(unifiedCategory)
            }
        }
        
        // 按名称排序
        return unifiedCategories.sorted { $0.name < $1.name }
    }
    
    /// 获取指定分类的图标列表
    /// - Parameter category: 统一图标分类
    /// - Returns: IconAsset数组
    func getIcons(for category: UnifiedIconCategory) async -> [IconAsset] {
        switch category.source {
        case .local:
            guard let localCategory = category.localCategory else { return [] }
            return localCategory.getAllIconAssets()
            
        case .remote:
            guard let remoteCategory = category.remoteCategory else { return [] }
            let remoteIcons = await remoteRepo.getIcons(for: remoteCategory.id)
            return remoteIcons.map { remoteIcon in
                IconAsset(remotePath: remoteIcon.path)
            }
        }
    }
    

    
    /// 获取图标的完整URL
    /// - Parameter iconPath: 图标路径
    /// - Returns: 图标的完整URL
    func getIconURL(for iconPath: String) -> URL? {
        return remoteRepo.getIconURL(for: iconPath)
    }
    
    /// 获取指定名称的分类
    /// - Parameter name: 分类名称
    /// - Returns: 统一图标分类实例，如果不存在则返回nil
    func getCategory(byName name: String) async -> UnifiedIconCategory? {
        let allCategories = await getAllCategories()
        return allCategories.first { $0.name == name }
    }
    
    /// 根据图标ID获取图标
    /// - Parameter iconId: 图标ID
    /// - Returns: IconAsset实例，如果找不到则返回nil
    func getIconAsset(byId iconId: String) async -> IconAsset? {
        // 首先在本地查找
        if let localIcon = localRepo.getIconAsset(byId: iconId) {
            return localIcon
        }
        
        // 在远程查找
        let allCategories = await getAllCategories()
        for category in allCategories where category.source == .remote {
            let icons = await getIcons(for: category)
            if let remoteIcon = icons.first(where: { $0.iconId == iconId }) {
                return remoteIcon
            }
        }
        
        return nil
    }
}



#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .setInitialTab("Icon")
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 800)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .setInitialTab("Icon")
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
