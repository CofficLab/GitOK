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
    func getAllIcons() async -> [IconAsset] {
        []
    }
    
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

    /// 缓存有效期
    private let cacheValidityDuration: TimeInterval = 60*60

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

    /// HTTP 层面的缓存时间
    private let httpCacheMaxAge: TimeInterval = 60*60

    /// 私有初始化方法，确保单例模式
    private init() {}

    // MARK: - IconSourceProtocol Implementation

    var sourceIdentifier: String { "gitok_api" }
    var sourceName: String { "网络图标库" }

    var isAvailable: Bool = true

    func getAllCategories(reason: String) async throws -> [IconCategory] {
        os_log(.info, "\(self.t)getAllCategories reason: \(reason)")
        let remoteCategories: [RemoteIconCategory]
        if isCacheValid() {
            remoteCategories = cachedCategories
        } else {
            let categories = try await fetchCategoriesFromNetwork()
            cachedCategories = categories
            lastCacheTime = Date()
            remoteCategories = categories
        }
        let mapped = remoteCategories.map { remoteCategory in
            IconCategory(
                id: remoteCategory.id,
                name: remoteCategory.name,
                displayName: remoteCategory.displayName,
                iconCount: remoteCategory.iconCount,
                sourceIdentifier: self.sourceIdentifier,
                metadata: ["remoteIconIds": remoteCategory.remoteIconIds.count]
            )
        }
        return mapped
    }

    func getCategory(byName name: String) async throws -> IconCategory? {
        let categories = try await getAllCategories(reason: "get_category_by_name")
        return categories.first { $0.name == name }
    }

    func getIconAsset(byId iconId: String) async throws -> IconAsset? {
        let categories = try await getAllCategories(reason: "get_icon_by_id")

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

    private func fetchCategoriesFromNetwork() async throws -> [RemoteIconCategory] {
        guard let url = URL(string: baseURL + manifestEndpoint) else {
            throw RemoteIconError.invalidURL
        }

        os_log("\(self.t)fetchCategoriesFromNetwork: \(url.absoluteString) with cacheMaxAge: \(self.httpCacheMaxAge)")

        // 使用显式 Header，避免 GET 携带 Content-Type；同时禁用压缩以排除解压问题
        let headers = [
            "Accept": "application/json",
            "Accept-Encoding": "identity",
            "User-Agent": "GitOK/1.0 (macOS; SwiftURLSession)"
        ]
        let (data, response) = try await url.httpGetData(headers: headers, cacheMaxAge: httpCacheMaxAge)
        let code = response.statusCode
        guard code == 200 else {
            throw RemoteIconError.networkError
        }
        // 预校验：不是合法JSON则直接抛错
        guard (try? JSONSerialization.jsonObject(with: data)) != nil else {
            throw RemoteIconError.decodingError
        }
        do {
            let manifest = try JSONDecoder().decode(IconManifest.self, from: data)
            let calcIcons = manifest.iconsByCategory.values.reduce(0) { $0 + $1.count }
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
            throw error
        }
    }

    // MARK: - 缓存管理

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
        // 同样覆盖 Header，避免 GET 携带 Content-Type
        let headers = [
            "Accept": "application/json",
            "Accept-Encoding": "identity",
            "User-Agent": "GitOK/1.0 (macOS; SwiftURLSession)"
        ]
        let (data, response) = try await url.httpGetData(headers: headers, cacheMaxAge: httpCacheMaxAge)
        let code = response.statusCode
        guard code == 200 else { throw RemoteIconError.networkError }
        let manifest = try JSONDecoder().decode(IconManifest.self, from: data)
        let categoryIcons = manifest.iconsByCategory[categoryId] ?? []
        os_log(.info, "\(self.t)icons for cat=\(categoryId): \(categoryIcons.count)")
        return categoryIcons.map { iconData in IconAsset(remotePath: iconData.path) }
    }

    // MARK: - 图标缓存管理

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
            let (data, response) = try await remoteURL.httpGetData(cacheMaxAge: httpCacheMaxAge)
            guard response.statusCode == 200 else { return false }
            // 保存到本地缓存
            try data.write(to: localCacheURL)
            os_log(.info, "\(self.t)图标缓存成功：\(iconPath)")
            return true
        } catch {
            os_log(.error, "\(self.t)图标下载失败：\(iconPath), 错误：\(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - 批量图标缓存
    
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
    
    // MARK: - 错误类型定义
    
    enum RemoteIconError: Error {
        case networkError
        case decodingError
        case invalidURL
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
    .frame(width: 650)
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
