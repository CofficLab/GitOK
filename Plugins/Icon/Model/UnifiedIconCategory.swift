import Foundation


// MARK: - 统一数据模型

/**
 * 统一图标分类
 * 整合本地和远程分类数据
 */
struct UnifiedIconCategory: Identifiable, Hashable {
    let id: URL
    let name: String
    let displayName: String
    let iconCount: Int
    let source: IconSource
    let localCategory: IconCategory?
    let remoteCategory: RemoteIconCategory?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: UnifiedIconCategory, rhs: UnifiedIconCategory) -> Bool {
        lhs.id == rhs.id
    }
}
