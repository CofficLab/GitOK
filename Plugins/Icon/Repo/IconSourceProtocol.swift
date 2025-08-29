import Foundation
import SwiftUI

/**
 * 图标来源协议
 * 定义了图标来源需要实现的基本接口
 * 所有图标来源（本地、远程等）都需要遵循此协议
 */
protocol IconSourceProtocol {
    /// 来源类型标识符
    var sourceType: IconSourceType { get }
    
    /// 来源名称（用于显示和调试）
    var sourceName: String { get }
    
    /// 是否可用（网络连接、文件访问权限等）
    var isAvailable: Bool { get async }
    
    /// 获取所有可用的图标分类
    /// - Returns: 分类数组
    func getAllCategories() async -> [IconCategoryInfo]
    
    /// 获取指定分类下的所有图标
    /// - Parameter categoryId: 分类标识符
    /// - Returns: 图标数组
    func getIcons(for categoryId: String) async -> [IconAsset]
    
    /// 根据图标ID获取图标资源
    /// - Parameter iconId: 图标ID
    /// - Returns: 图标资源，如果找不到则返回nil
    func getIconAsset(byId iconId: String) async -> IconAsset?
    
    /// 根据分类名称获取分类信息
    /// - Parameter name: 分类名称
    /// - Returns: 分类信息，如果找不到则返回nil
    func getCategory(byName name: String) async -> IconCategoryInfo?
}

/**
 * 图标来源类型枚举
 * 用于标识不同类型的图标来源
 */
enum IconSourceType: String, CaseIterable {
    case local = "local"
    case remote = "remote"
    case thirdParty = "third_party"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .local:
            return "本地图标"
        case .remote:
            return "远程图标"
        case .thirdParty:
            return "第三方图标"
        case .custom:
            return "自定义图标"
        }
    }
}

/**
 * 图标分类信息结构体
 * 标准化不同来源的分类信息
 */
struct IconCategoryInfo: Identifiable, Hashable {
    /// 分类唯一标识符
    let id: String
    
    /// 分类名称
    let name: String
    
    /// 分类显示名称
    let displayName: String
    
    /// 图标数量
    let iconCount: Int
    
    /// 来源类型
    let sourceType: IconSourceType
    
    /// 来源标识（用于区分同一类型下的不同来源）
    let sourceIdentifier: String
    
    /// 额外元数据（各来源可自定义使用）
    let metadata: [String: Any]
    
    init(
        id: String,
        name: String,
        displayName: String? = nil,
        iconCount: Int,
        sourceType: IconSourceType,
        sourceIdentifier: String,
        metadata: [String: Any] = [:]
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName ?? name.uppercased()
        self.iconCount = iconCount
        self.sourceType = sourceType
        self.sourceIdentifier = sourceIdentifier
        self.metadata = metadata
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(sourceType)
        hasher.combine(sourceIdentifier)
    }
    
    static func == (lhs: IconCategoryInfo, rhs: IconCategoryInfo) -> Bool {
        return lhs.id == rhs.id && 
               lhs.sourceType == rhs.sourceType && 
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
