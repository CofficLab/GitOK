import Foundation
import MagicCore
import MagicAll
import MagicHttp
import OSLog
import SwiftUI

/**
 * 远程图标仓库
 * 负责从网络API获取图标分类和图标数据
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

    /// HTTP 层面的缓存时间
    private let httpCacheMaxAge: TimeInterval = 60 * 60

    /// 私有初始化方法，确保单例模式
    private init() {}

    // MARK: - IconSourceProtocol Implementation

    var sourceIdentifier: String { "gitok_api" }
    var sourceName: String { "网络图标库" }

    var isAvailable: Bool = true

    func getAllCategories(reason: String) async throws -> [IconCategory] {
        os_log(.info, "\(self.t)getAllCategories reason: \(reason)")
        let remoteCategories: [RemoteIconCategory]
        let categories = try await fetchCategoriesFromNetwork()
        remoteCategories = categories

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
                // 模糊匹配：检查iconId是否包含在URL中
                if let urlString = icon.fileURL?.absoluteString, urlString.contains(iconId) {
                    return true
                }
                // 检查URL的最后一部分（去掉扩展名）
                if let url = icon.fileURL {
                    let lastComponent = url.lastPathComponent
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
            "User-Agent": "GitOK/1.0 (macOS; SwiftURLSession)",
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

    /// 获取指定分类的图标列表
    /// - Parameter categoryId: 分类ID
    /// - Returns: IconAsset数组
    func getIcons(for categoryId: String) async -> [IconAsset] {
        do {
            return try await fetchIconsFromNetwork(for: categoryId)
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
            "User-Agent": "GitOK/1.0 (macOS; SwiftURLSession)",
        ]
        let (data, response) = try await url.httpGetData(headers: headers, cacheMaxAge: httpCacheMaxAge)
        let code = response.statusCode
        guard code == 200 else { throw RemoteIconError.networkError }
        let manifest = try JSONDecoder().decode(IconManifest.self, from: data)
        let categoryIcons = manifest.iconsByCategory[categoryId] ?? []
        os_log(.info, "\(self.t)icons for cat=\(categoryId): \(categoryIcons.count)")
        return categoryIcons.map { iconData in
            let remoteURL = URL(string: baseURL + "/icons/" + iconData.path)!
            return IconAsset(remoteURL: remoteURL)
        }
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
