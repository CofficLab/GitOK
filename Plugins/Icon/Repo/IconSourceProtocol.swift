import Foundation
import SwiftUI

/**
 * 图标来源协议
 * 定义了图标来源需要实现的基本接口
 * 所有图标来源（本地、远程、自定义等）都需要遵循此协议
 */
protocol IconSourceProtocol {
    /// 来源唯一标识（用于精确区分不同来源实例）
    var sourceIdentifier: String { get }
    
    /// 来源名称（用于显示和调试）
    var sourceName: String { get }
    
    /// 是否可用（网络连接、文件访问权限等）
    var isAvailable: Bool { get async }
    
    /// 该来源是否支持增删图标
    var supportsMutations: Bool { get }
    
    /// 该来源是否支持分类
    var supportsCategories: Bool { get }
    
    /// 获取所有可用的图标分类
    /// - Returns: 分类数组
    /// - Throws: 当数据源不可用或解析失败时抛出错误
    func getAllCategories() async throws -> [IconCategory]
    
    /// 获取指定分类下的所有图标
    /// - Parameter categoryId: 分类标识符
    /// - Returns: 图标数组
    func getIcons(for categoryId: String) async -> [IconAsset]
    
    /// 获取该来源下的所有图标（当不支持分类时调用）
    func getAllIcons() async -> [IconAsset]
    
    /// 根据图标ID获取图标资源
    /// - Parameter iconId: 图标ID
    /// - Returns: 图标资源，如果找不到则返回nil
    /// - Throws: 当底层数据源拉取/解析失败时抛出错误
    func getIconAsset(byId iconId: String) async throws -> IconAsset?
    
    /// 根据分类名称获取分类信息
    /// - Parameter name: 分类名称
    /// - Returns: 分类信息，如果找不到则返回nil
    /// - Throws: 当底层数据源拉取/解析失败时抛出错误
    func getCategory(byName name: String) async throws -> IconCategory?
    
    /// 添加图片（默认不支持）
    func addImage(data: Data, filename: String) async -> Bool
    
    /// 删除图片（默认不支持）
    func deleteImage(filename: String) async -> Bool
}

extension IconSourceProtocol {
    var supportsMutations: Bool { false }
    var supportsCategories: Bool { true }
    
    func getAllIcons() async -> [IconAsset] {
        // 默认实现：聚合所有分类下的图标
        let categories = (try? await getAllCategories()) ?? []
        var all: [IconAsset] = []
        for category in categories {
            let icons = await getIcons(for: category.id)
            all.append(contentsOf: icons)
        }
        return all
    }
    func addImage(data: Data, filename: String) async -> Bool { false }
    func deleteImage(filename: String) async -> Bool { false }
}

/**
 * 图标分类信息结构体
 * 标准化不同来源的分类信息
 */
struct IconCategory: Identifiable, Hashable {
    /// 分类唯一标识符
    let id: String
    
    /// 分类名称
    let name: String
    
    /// 分类显示名称
    let displayName: String
    
    /// 图标数量
    let iconCount: Int
    
    /// 来源标识（用于区分不同来源）
    let sourceIdentifier: String
    
    /// 额外元数据（各来源可自定义使用）
    let metadata: [String: Any]
    
    init(
        id: String,
        name: String,
        displayName: String? = nil,
        iconCount: Int,
        sourceIdentifier: String,
        metadata: [String: Any] = [:]
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName ?? name.uppercased()
        self.iconCount = iconCount
        self.sourceIdentifier = sourceIdentifier
        self.metadata = metadata
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(sourceIdentifier)
    }
    
    static func == (lhs: IconCategory, rhs: IconCategory) -> Bool {
        return lhs.id == rhs.id &&
               lhs.sourceIdentifier == rhs.sourceIdentifier
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
