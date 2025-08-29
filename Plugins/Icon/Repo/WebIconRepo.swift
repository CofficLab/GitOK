import Foundation
import MagicCore
import OSLog
import SwiftUI

/**
 * 远程图标仓库
 * 负责从网络API获取图标分类和图标数据
 * 支持缓存机制和本地图标缓存，提升加载性能
 * 实现 IconSourceProtocol 协议，提供统一的图标来源接口
 */
class WebIconRepo: SuperLog, IconSourceProtocol {
    nonisolated static var emoji: String { "🛜" }

    /// 单例实例
    static let shared = WebIconRepo()

    /// 远程API的基础URL
    private let baseURL: String = "https://gitok.coffic.cn"

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

    // MARK: - IconSourceProtocol Implementation

    var sourceIdentifier: String { "gitok_api" }
    var sourceName: String { "网络图标库" }

    var isAvailable: Bool {
        get async {
            do {
                guard let url = URL(string: baseURL + manifestEndpoint) else { print("[WebIconRepo] isAvailable invalid URL"); return false }
                print("[WebIconRepo] isAvailable checking: \(url.absoluteString)")
                let (_, response) = try await URLSession.shared.data(from: url)
                let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                print("[WebIconRepo] isAvailable status: \(code)")
                return code == 200
            } catch {
                print("[WebIconRepo] isAvailable error: \(error)")
                return false
            }
        }
    }

    func getAllCategories() async -> [IconCategoryInfo] {
        print("[WebIconRepo] getAllCategories begin (cached: \(cachedCategories.count))")
        let remoteCategories = await getAllRemoteCategories()
        print("[WebIconRepo] getAllCategories remote count: \(remoteCategories.count)")
        let mapped = remoteCategories.map { remoteCategory in
            IconCategoryInfo(
                id: remoteCategory.id,
                name: remoteCategory.name,
                displayName: remoteCategory.displayName,
                iconCount: remoteCategory.iconCount,
                sourceIdentifier: self.sourceIdentifier,
                metadata: ["remoteIconIds": remoteCategory.remoteIconIds.count]
            )
        }
        print("[WebIconRepo] getAllCategories mapped count: \(mapped.count)")
        return mapped
    }

    func getCategory(byName name: String) async -> IconCategoryInfo? {
        let categories = await getAllCategories()
        return categories.first { $0.name == name }
    }

    func getIconAsset(byId iconId: String) async -> IconAsset? {
        let categories = await getAllCategories()

        for category in categories {
            let icons = await getIcons(for: category.id)
            // 改进匹配逻辑：支持多种匹配方式
            if let remoteIcon = icons.first(where: { icon in
                // 精确匹配iconId
                if icon.iconId == iconId {
                    return true
                }
                // 模糊匹配：检查iconId是否包含在路径中
                if icon.remotePath?.contains(iconId) == true {
                    return true
                }
                // 检查路径的最后一部分（去掉扩展名）
                if let path = icon.remotePath {
                    let lastComponent = path.components(separatedBy: "/").last ?? ""
                    let withoutExtension = lastComponent.replacingOccurrences(of: ".svg", with: "")
                        .replacingOccurrences(of: ".png", with: "")
                        .replacingOccurrences(of: ".jpg", with: "")
                        .replacingOccurrences(of: ".jpeg", with: "")
                    if withoutExtension == iconId {
                        return true
                    }
                }
                return false
            }) {
                return remoteIcon
            }
        }

        return nil
    }

    /// 获取所有远程图标分类（兼容旧接口）
    /// - Returns: RemoteIconCategory 数组
    func getAllRemoteCategories() async -> [RemoteIconCategory] {
        // 检查缓存是否有效
        if isCacheValid() {
            print("[WebIconRepo] using cached categories: \(cachedCategories.count)")
            return cachedCategories
        }

        // 从网络获取数据
        do {
            print("[WebIconRepo] fetching categories from network...")
            let categories = try await fetchCategoriesFromNetwork()
            cachedCategories = categories
            lastCacheTime = Date()
            print("[WebIconRepo] fetched categories: \(categories.count)")
            return categories
        } catch {
            print("[WebIconRepo] fetch categories error: \(error), return cached: \(cachedCategories.count)")
            return cachedCategories
        }
    }

    /// 从网络获取分类数据
    /// - Returns: 远程图标分类数组
    /// - Throws: 网络请求错误
    private func fetchCategoriesFromNetwork() async throws -> [RemoteIconCategory] {
        guard let url = URL(string: baseURL + manifestEndpoint) else {
            print("[WebIconRepo] fetchCategories invalid URL: \(baseURL + manifestEndpoint)")
            throw RemoteIconError.invalidURL
        }
        print("[WebIconRepo] fetchCategories GET: \(url.absoluteString)")
        let (data, response) = try await URLSession.shared.data(from: url)
        let code = (response as? HTTPURLResponse)?.statusCode ?? -1
        print("[WebIconRepo] fetchCategories status: \(code), bytes: \(data.count)")
        guard code == 200 else {
            throw RemoteIconError.networkError
        }
        do {
            let manifest = try JSONDecoder().decode(IconManifest.self, from: data)
            print("[WebIconRepo] manifest categories: \(manifest.categories.count)")
            return manifest.categories.map { categoryData in
                RemoteIconCategory(
                    id: categoryData.id,
                    name: categoryData.name,
                    displayName: categoryData.name.uppercased(),
                    iconCount: categoryData.count,
                    remoteIconIds: manifest.iconsByCategory[categoryData.id] ?? []
                )
            }
        } catch {
            print("[WebIconRepo] decode manifest error: \(error)")
            throw error
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
            print("[WebIconRepo] getIcons cached for \(categoryId): \(cachedIcons.count)")
            return cachedIcons
        }

        // 从网络获取数据
        do {
            print("[WebIconRepo] getIcons fetch for: \(categoryId)")
            let icons = try await fetchIconsFromNetwork(for: categoryId)
            // 更新缓存
            cachedIconsByCategory[categoryId] = icons
            lastIconCacheTimeByCategory[categoryId] = Date()
            print("[WebIconRepo] getIcons fetched count: \(icons.count)")
            return icons
        } catch {
            print("[WebIconRepo] getIcons error: \(error)")
            return []
        }
    }

    /// 从网络获取指定分类的图标数据
    /// - Parameter categoryId: 分类ID
    /// - Returns: IconAsset数组
    /// - Throws: 网络请求错误
    private func fetchIconsFromNetwork(for categoryId: String) async throws -> [IconAsset] {
        guard let url = URL(string: baseURL + manifestEndpoint) else {
            print("[WebIconRepo] fetchIcons invalid URL")
            throw RemoteIconError.invalidURL
        }
        print("[WebIconRepo] fetchIcons GET manifest: \(url.absoluteString), category: \(categoryId)")
        let (data, response) = try await URLSession.shared.data(from: url)
        let code = (response as? HTTPURLResponse)?.statusCode ?? -1
        print("[WebIconRepo] fetchIcons status: \(code), bytes: \(data.count)")
        guard code == 200 else { throw RemoteIconError.networkError }
        let manifest = try JSONDecoder().decode(IconManifest.self, from: data)
        let categoryIcons = manifest.iconsByCategory[categoryId] ?? []
        print("[WebIconRepo] fetchIcons category \(categoryId) icon records: \(categoryIcons.count)")
        return categoryIcons.map { iconData in IconAsset(remotePath: iconData.path) }
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
            .hideTabPicker()
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
            .hideTabPicker()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 1200)
}
