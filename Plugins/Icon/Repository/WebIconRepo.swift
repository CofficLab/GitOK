import Foundation
import SwiftUI
import OSLog
import MagicCore

/**
 * 远程图标仓库
 * 负责从网络API获取图标分类和图标数据
 * 支持缓存机制，避免重复网络请求
 * 支持本地图标缓存，提升加载性能
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
    
    /// 分类图标缓存
    /// Key: 分类ID, Value: 图标数组
    private var cachedIconsByCategory: [String: [IconAsset]] = [:]
    
    /// 分类图标缓存时间戳
    /// Key: 分类ID, Value: 缓存时间
    private var lastIconCacheTimeByCategory: [String: Date] = [:]
    
    /// 本地图标缓存目录
    private lazy var localCacheDir: URL = {
        let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "GitOK"
        let cacheDir = appSupportDir.appendingPathComponent(appName).appendingPathComponent("icon_cache")
        
        // 确保缓存目录存在
        if !FileManager.default.fileExists(atPath: cacheDir.path) {
            try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        }
        
        return cacheDir
    }()
    
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
    
    /// 检查指定分类的图标缓存是否有效
    /// - Parameter categoryId: 分类ID
    /// - Returns: 缓存是否有效
    private func isIconCacheValid(for categoryId: String) -> Bool {
        guard let lastCacheTime = lastIconCacheTimeByCategory[categoryId] else { return false }
        return Date().timeIntervalSince(lastCacheTime) < cacheValidityDuration
    }
    
    /// 获取指定分类的图标列表
    /// - Parameter categoryId: 分类ID
    /// - Returns: IconAsset数组
    func getIcons(for categoryId: String) async -> [IconAsset] {
        // 检查缓存是否有效
        if isIconCacheValid(for: categoryId),
           let cachedIcons = cachedIconsByCategory[categoryId] {
            return cachedIcons
        }
        
        // 从网络获取数据
        do {
            let icons = try await fetchIconsFromNetwork(for: categoryId)
            // 更新缓存
            cachedIconsByCategory[categoryId] = icons
            lastIconCacheTimeByCategory[categoryId] = Date()
            return icons
        } catch {
            os_log(.error, "\(self.t)获取分类图标失败：\(error.localizedDescription)")
            return []
        }
    }
    
    /// 从网络获取指定分类的图标数据
    /// - Parameter categoryId: 分类ID
    /// - Returns: IconAsset数组
    /// - Throws: 网络请求错误
    private func fetchIconsFromNetwork(for categoryId: String) async throws -> [IconAsset] {
        guard let url = URL(string: baseURL + manifestEndpoint) else {
            throw RemoteIconError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw RemoteIconError.networkError
        }
        
        let manifest = try JSONDecoder().decode(IconManifest.self, from: data)
        let categoryIcons = manifest.iconsByCategory[categoryId] ?? []
        
        return categoryIcons.map { iconData in
            IconAsset(remotePath: iconData.path)
        }
    }
    
    /// 获取图标的完整URL
    /// 优先返回本地缓存的图标，如果没有则返回网络URL
    /// - Parameter iconPath: 图标路径
    /// - Returns: 图标的完整URL（本地缓存优先）
    func getIconURL(for iconPath: String) -> URL? {
        // 首先检查本地缓存
        let localCacheURL = getLocalCacheURL(for: iconPath)
        if FileManager.default.fileExists(atPath: localCacheURL.path) {
            return localCacheURL
        }
        
        // 如果本地没有，返回网络URL
        return URL(string: baseURL + "/icons/" + iconPath)
    }
    
    /// 获取图标的本地缓存URL
    /// - Parameter iconPath: 图标路径
    /// - Returns: 本地缓存URL
    private func getLocalCacheURL(for iconPath: String) -> URL {
        // 使用路径的哈希值作为文件名，避免路径过长问题
        let fileName = String(iconPath.hashValue) + ".png"
        return localCacheDir.appendingPathComponent(fileName)
    }
    
    /// 下载并缓存图标到本地
    /// - Parameter iconPath: 图标路径
    /// - Returns: 是否下载成功
    func downloadAndCacheIcon(for iconPath: String) async -> Bool {
        // 检查本地是否已有缓存
        let localCacheURL = getLocalCacheURL(for: iconPath)
        if FileManager.default.fileExists(atPath: localCacheURL.path) {
            return true
        }
        
        // 从网络下载图标
        guard let remoteURL = URL(string: baseURL + "/icons/" + iconPath) else {
            return false
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: remoteURL)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return false
            }
            
            // 保存到本地缓存
            try data.write(to: localCacheURL)
            os_log(.info, "\(self.t)图标缓存成功：\(iconPath)")
            return true
            
        } catch {
            os_log(.error, "\(self.t)图标下载失败：\(iconPath), 错误：\(error.localizedDescription)")
            return false
        }
    }
    
    /// 批量下载并缓存分类下的所有图标
    /// - Parameter categoryId: 分类ID
    /// - Returns: 成功缓存的图标数量
    func downloadAndCacheCategoryIcons(for categoryId: String) async -> Int {
        let icons = await getIcons(for: categoryId)
        var successCount = 0
        
        for icon in icons {
            if let remotePath = icon.remotePath,
               await downloadAndCacheIcon(for: remotePath) {
                successCount += 1
            }
        }
        
        os_log(.info, "\(self.t)分类 \(categoryId) 图标缓存完成：\(successCount)/\(icons.count)")
        return successCount
    }
    
    /// 清除所有缓存
    /// 用于强制刷新数据
    func clearCache() {
        cachedCategories.removeAll()
        cachedIconsByCategory.removeAll()
        lastCacheTime = nil
        lastIconCacheTimeByCategory.removeAll()
    }
    
    /// 清除指定分类的图标缓存
    /// - Parameter categoryId: 分类ID
    func clearIconCache(for categoryId: String) {
        cachedIconsByCategory.removeValue(forKey: categoryId)
        lastIconCacheTimeByCategory.removeValue(forKey: categoryId)
    }
    
    /// 清除本地图标文件缓存
    /// - Parameter iconPath: 图标路径，如果为nil则清除所有
    func clearLocalIconCache(for iconPath: String? = nil) {
        if let iconPath = iconPath {
            // 清除指定图标
            let localCacheURL = getLocalCacheURL(for: iconPath)
            try? FileManager.default.removeItem(at: localCacheURL)
        } else {
            // 清除所有本地图标缓存
            try? FileManager.default.removeItem(at: localCacheDir)
            try? FileManager.default.createDirectory(at: localCacheDir, withIntermediateDirectories: true)
        }
    }
    
    /// 获取本地缓存统计信息
    /// - Returns: 缓存统计信息
    func getLocalCacheStats() -> (totalFiles: Int, totalSize: Int64) {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: localCacheDir, includingPropertiesForKeys: [.fileSizeKey])
            let totalSize = files.reduce(Int64(0)) { sum, url in
                let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                return sum + Int64(size)
            }
            return (files.count, totalSize)
        } catch {
            return (0, 0)
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
    .frame(width: 1200)
    .frame(height: 1200)
}
