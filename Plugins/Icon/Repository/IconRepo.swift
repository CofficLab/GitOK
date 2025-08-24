import Foundation
import SwiftUI
import OSLog
import MagicCore

/**
 * 统一图标仓库管理器
 * 整合本地和远程图标仓库，提供统一的接口
 * 支持本地优先、远程补充的数据获取策略
 */
class IconRepo: SuperLog {
    nonisolated static var emoji: String { "🔗" }
    
    /// 单例实例
    static let shared = IconRepo()
    
    /// 本地图标仓库
    private let localRepo = AppIconRepo.shared
    
    /// 远程API的基础URL
    private let baseURL = "https://gitok.coffic.cn"
    
    /// 图标清单API端点
    private let manifestEndpoint = "/icon-manifest.json"
    
    /// 缓存的数据
    private var cachedCategories: [RemoteIconCategory] = []
    
    /// 缓存时间戳
    private var lastCacheTime: Date?
    
    /// 缓存有效期（5分钟）
    private let cacheValidityDuration: TimeInterval = 300
    
    /// 私有初始化方法，确保单例模式
    private init() {}
    
    /// 获取所有可用的图标分类（本地 + 远程）
    /// - Returns: 统一图标分类数组
    func getAllCategories() async -> [UnifiedIconCategory] {
        // 获取本地分类
        let localCategories = localRepo.getAllCategories()
        
        // 获取远程分类
        let remoteCategories = await getRemoteCategories()
        
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
    
    /// 获取远程图标分类
    /// - Returns: 远程图标分类数组
    private func getRemoteCategories() async -> [RemoteIconCategory] {
        // 检查缓存是否有效
        if isCacheValid() {
            return cachedCategories
        }
        
        // 从网络获取数据
        do {
            let categories = try await fetchCategoriesFromNetwork()
            cachedCategories = categories
            lastCacheTime = Date()
            return categories
        } catch {
            os_log(.error, "\(self.t)获取远程分类失败：\(error.localizedDescription)")
            return []
        }
    }
    
    /// 从网络获取分类数据
    /// - Returns: 远程图标分类数组
    /// - Throws: 网络请求错误
    private func fetchCategoriesFromNetwork() async throws -> [RemoteIconCategory] {
        guard let url = URL(string: baseURL + manifestEndpoint) else {
            throw RemoteIconError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw RemoteIconError.networkError
        }
        
        let manifest = try JSONDecoder().decode(IconManifest.self, from: data)
        return manifest.categories.map { categoryData in
            RemoteIconCategory(
                id: categoryData.id,
                name: categoryData.name,
                displayName: categoryData.name.uppercased(),
                iconCount: categoryData.count,
                remoteIconIds: manifest.iconsByCategory[categoryData.id] ?? []
            )
        }
    }
    
    /// 检查缓存是否有效
    /// - Returns: 缓存是否有效
    private func isCacheValid() -> Bool {
        guard let lastCacheTime = lastCacheTime else { return false }
        return Date().timeIntervalSince(lastCacheTime) < cacheValidityDuration
    }
    
    /// 获取指定分类的图标列表
    /// - Parameter category: 统一图标分类
    /// - Returns: 统一图标数组
    func getIcons(for category: UnifiedIconCategory) async -> [UnifiedIcon] {
        switch category.source {
        case .local:
            guard let localCategory = category.localCategory else { return [] }
            let localIcons = localCategory.getAllIconAssets()
            return localIcons.map { iconAsset in
                UnifiedIcon(
                    id: iconAsset.id,
                    name: iconAsset.iconId,
                    source: .local,
                    localIcon: iconAsset,
                    remoteIcon: nil
                )
            }
            
        case .remote:
            guard let remoteCategory = category.remoteCategory else { return [] }
            let remoteIcons = await getRemoteIcons(for: remoteCategory.id)
            return remoteIcons.map { remoteIcon in
                UnifiedIcon(
                    id: remoteIcon.id,
                    name: remoteIcon.name,
                    source: .remote,
                    localIcon: nil,
                    remoteIcon: remoteIcon
                )
            }
        }
    }
    
    /// 获取指定分类的远程图标列表
    /// - Parameter categoryId: 分类ID
    /// - Returns: 远程图标数组
    private func getRemoteIcons(for categoryId: String) async -> [RemoteIcon] {
        guard let url = URL(string: baseURL + manifestEndpoint) else {
            return []
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return []
            }
            
            let manifest = try JSONDecoder().decode(IconManifest.self, from: data)
            let categoryIcons = manifest.iconsByCategory[categoryId] ?? []
            
            return categoryIcons.map { iconData in
                RemoteIcon(
                    id: iconData.name,
                    name: iconData.name,
                    path: iconData.path,
                    category: iconData.category,
                    fullPath: iconData.fullPath,
                    size: iconData.size,
                    modified: iconData.modified
                )
            }
        } catch {
            os_log(.error, "\(self.t)获取分类图标失败：\(error.localizedDescription)")
            return []
        }
    }
    
    /// 获取图标的完整URL
    /// - Parameter iconPath: 图标路径
    /// - Returns: 图标的完整URL
    func getIconURL(for iconPath: String) -> URL? {
        return URL(string: baseURL + "/icons/" + iconPath)
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
    /// - Returns: 统一图标实例，如果找不到则返回nil
    func getIconAsset(byId iconId: String) async -> UnifiedIcon? {
        // 首先在本地查找
        if let localIcon = localRepo.getIconAsset(byId: iconId) {
            return UnifiedIcon(
                id: localIcon.id,
                name: localIcon.iconId,
                source: .local,
                localIcon: localIcon,
                remoteIcon: nil
            )
        }
        
        // 在远程查找
        let allCategories = await getAllCategories()
        for category in allCategories where category.source == .remote {
            let icons = await getIcons(for: category)
            if let remoteIcon = icons.first(where: { $0.name == iconId }) {
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
