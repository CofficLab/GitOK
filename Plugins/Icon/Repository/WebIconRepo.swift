import Foundation
import SwiftUI
import OSLog
import MagicCore

/**
 * 远程图标仓库
 * 负责从网络API获取图标分类和图标数据
 * 支持缓存机制，避免重复网络请求
 */
class WebIconRepo: SuperLog {
    nonisolated static var emoji: String { "🌐" }
    
    /// 单例实例
    static let shared = WebIconRepo()
    
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
    
    /// 获取所有远程图标分类
    /// - Returns: 远程图标分类数组
    func getAllCategories() async -> [RemoteIconCategory] {
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
    /// - Parameter categoryId: 分类ID
    /// - Returns: 远程图标数组
    func getIcons(for categoryId: String) async -> [RemoteIcon] {
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
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .setInitialTab("Icon")
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
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
