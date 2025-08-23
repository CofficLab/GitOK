import Foundation
import SwiftUI
import OSLog
import MagicCore

/**
 * 远程图标仓库
 * 负责从网络API获取图标分类和图标数据
 * 支持缓存机制，避免重复网络请求
 */
class RemoteIconRepo: SuperLog {
    nonisolated static var emoji: String { "🌐" }
    
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

// MARK: - 数据模型

/**
 * 远程图标分类
 * 对应网络API返回的分类数据结构
 */
struct RemoteIconCategory: Identifiable, Hashable {
    let id: String
    let name: String
    let displayName: String
    let iconCount: Int
    let remoteIconIds: [IconData]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: RemoteIconCategory, rhs: RemoteIconCategory) -> Bool {
        lhs.id == rhs.id
    }
}

/**
 * 远程图标
 * 对应网络API返回的图标数据结构
 */
struct RemoteIcon: Identifiable, Hashable {
    let id: String
    let name: String
    let path: String
    let category: String
    let fullPath: String
    let size: Int
    let modified: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: RemoteIcon, rhs: RemoteIcon) -> Bool {
        lhs.id == rhs.id
    }
}

/**
 * 图标清单数据结构
 * 对应API返回的JSON数据结构
 */
struct IconManifest: Codable {
    let generatedAt: String
    let totalIcons: Int
    let totalCategories: Int
    let categories: [CategoryData]
    let iconsByCategory: [String: [IconData]]
    
    enum CodingKeys: String, CodingKey {
        case generatedAt
        case totalIcons
        case totalCategories
        case categories
        case iconsByCategory
    }
}

/**
 * 分类数据结构
 * 对应API返回的分类数据
 */
struct CategoryData: Codable {
    let id: String
    let name: String
    let count: Int
}

/**
 * 图标数据结构
 * 对应API返回的图标数据
 */
struct IconData: Codable {
    let name: String
    let path: String
    let category: String
    let fullPath: String
    let size: Int
    let modified: String
}

// MARK: - 错误类型

/**
 * 远程图标仓库错误类型
 */
enum RemoteIconError: Error, LocalizedError {
    case invalidURL
    case networkError
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .networkError:
            return "网络请求失败"
        case .decodingError:
            return "数据解析失败"
        }
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
