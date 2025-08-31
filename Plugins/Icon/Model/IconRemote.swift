import Foundation
import SwiftUI

// MARK: - 远程图标相关结构体

/**
 * 远程图标分类
 * 对应网络API返回的分类数据结构
 */
struct RemoteIconCategory: Identifiable, Hashable {
    let id: String
    let name: String
    let displayName: String
    let iconCount: Int
    let remoteIconIds: [RemoteIconData]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: RemoteIconCategory, rhs: RemoteIconCategory) -> Bool {
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
    let iconsByCategory: [String: [RemoteIconData]]
    
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
 * 远程图标数据结构
 * 对应API返回的图标数据
 */
struct RemoteIconData: Codable {
    let name: String
    let path: String
    let category: String
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
            .setInitialTab(IconPlugin.label)
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
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

