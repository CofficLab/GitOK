import Foundation
import SwiftUI

/**
 * 图标分类模型
 * 用于管理图标分类的数据结构和相关操作
 */
struct IconCategory: Identifiable, Hashable {
    /// 分类的唯一标识符
    let id = UUID()
    
    /// 分类名称
    let name: String
    
    /// 分类下的图标数量
    let iconCount: Int
    
    /// 分类下的所有图标ID（支持数字ID和哈希文件名）
    let iconIds: [String]
    
    /// 分类的显示名称（用于UI显示）
    var displayName: String {
        name.uppercased()
    }
    
    /// 分类是否为空（没有图标）
    var isEmpty: Bool {
        iconCount == 0
    }
    
    /// 初始化方法
    /// - Parameters:
    ///   - name: 分类名称
    ///   - iconCount: 图标数量
    ///   - iconIds: 图标ID数组（支持数字ID和哈希文件名）
    init(name: String, iconCount: Int = 0, iconIds: [String] = []) {
        self.name = name
        self.iconCount = iconCount
        self.iconIds = iconIds
    }
    
    /// 从文件夹路径创建分类
    /// - Parameter folderPath: 分类文件夹路径
    /// - Returns: 分类实例，如果路径无效则返回nil
    static func fromFolder(_ folderPath: String) -> IconCategory? {
        let folderName = (folderPath as NSString).lastPathComponent
        
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: folderPath)
            // 支持多种图标文件格式
            let supportedFormats = ["png", "svg", "jpg", "jpeg", "gif", "webp"]
            let iconFiles = files.filter { filename in
                let fileExtension = filename.lowercased()
                return supportedFormats.contains { format in
                    fileExtension.hasSuffix(".\(format)")
                }
            }
            
            // 对于哈希文件名，我们使用文件名本身作为ID
            // 对于数字文件名，我们使用数字作为ID
            let iconIds = iconFiles.compactMap { filename -> String? in
                let nameWithoutExt = (filename as NSString).deletingPathExtension
                // 尝试转换为数字，如果失败则使用原始文件名
                if let numericId = Int(nameWithoutExt) {
                    return String(numericId)
                } else {
                    // 哈希文件名，直接使用
                    return nameWithoutExt
                }
            }.sorted()
            
            return IconCategory(
                name: folderName,
                iconCount: iconFiles.count,
                iconIds: iconIds
            )
        } catch {
            print("无法读取分类文件夹 \(folderPath): \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 获取指定ID的图标
    /// - Parameter iconId: 图标ID（支持数字ID和哈希文件名）
    /// - Returns: 图标Image，如果不存在则返回默认图标
    func getIcon(_ iconId: String) -> Image {
        guard iconIds.contains(iconId) else {
            return Image(systemName: "photo")
        }
        
        // 使用 IconAsset 来智能查找图标文件
        return IconAsset.getImage(category: name, iconId: iconId)
    }
    
    /// 获取指定ID的缩略图
    /// - Parameter iconId: 图标ID（支持数字ID和哈希文件名）
    /// - Returns: 缩略图Image，如果不存在则返回默认图标
    func getThumbnail(_ iconId: String) -> Image {
        guard iconIds.contains(iconId) else {
            return Image(systemName: "photo")
        }
        
        // 使用 IconAsset 来智能查找图标文件
        return IconAsset.getThumbnail(category: name, iconId: iconId)
    }
    
    /// 检查是否包含指定ID的图标
    /// - Parameter iconId: 图标ID（支持数字ID和哈希文件名）
    /// - Returns: 是否包含该图标
    func containsIcon(_ iconId: String) -> Bool {
        iconIds.contains(iconId)
    }
    
    /// 获取分类的统计信息
    /// - Returns: 包含统计信息的字典
    func getStatistics() -> [String: Any] {
        return [
            "name": name,
            "iconCount": iconCount,
            "iconIds": iconIds,
            "isEmpty": isEmpty,
            "firstIconId": iconIds.first ?? "",
            "lastIconId": iconIds.last ?? ""
        ]
    }
}

// MARK: - 图标分类管理器
class IconCategoryManager: ObservableObject {
    /// 所有可用的分类
    @Published private(set) var categories: [IconCategory] = []
    
    /// 当前选中的分类
    @Published var selectedCategory: IconCategory?
    
    /// 分类是否正在加载
    @Published private(set) var isLoading = false
    
    /// 初始化方法
    init() {
        refreshCategories()
    }
    
    /// 刷新分类列表
    func refreshCategories() {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let newCategories = self?.loadCategories() ?? []
            
            DispatchQueue.main.async {
                self?.categories = newCategories
                self?.isLoading = false
                
                // 如果当前选中的分类不存在，选择第一个
                if let selected = self?.selectedCategory,
                   !newCategories.contains(where: { $0.name == selected.name }) {
                    self?.selectedCategory = newCategories.first
                }
                
                // 如果没有选中的分类，选择第一个
                if self?.selectedCategory == nil && !newCategories.isEmpty {
                    self?.selectedCategory = newCategories.first
                }
            }
        }
    }
    
    /// 选择分类
    /// - Parameter category: 要选择的分类
    func selectCategory(_ category: IconCategory) {
        selectedCategory = category
    }
    
    /// 根据名称选择分类
    /// - Parameter name: 分类名称
    func selectCategory(byName name: String) {
        print("🎯 IconCategoryManager: 尝试选择分类 '\(name)'")
        print("🎯 可用分类: \(categories.map { $0.name })")
        
        if let category = categories.first(where: { $0.name == name }) {
            print("🎯 找到分类，设置为选中: \(category.name)")
            selectedCategory = category
        } else {
            print("🎯 未找到分类 '\(name)'")
        }
    }
    
    /// 获取指定名称的分类
    /// - Parameter name: 分类名称
    /// - Returns: 分类实例，如果不存在则返回nil
    func getCategory(byName name: String) -> IconCategory? {
        categories.first { $0.name == name }
    }
    
    /// 加载分类列表
    /// - Returns: 分类数组
    private func loadCategories() -> [IconCategory] {
        guard let iconFolderURL = IconAsset.iconFolderURL else {
            print("未找到图标文件夹")
            return []
        }
        
        do {
            let items = try FileManager.default.contentsOfDirectory(atPath: iconFolderURL.path)
            let categories = items.compactMap { item -> IconCategory? in
                let itemPath = (iconFolderURL.path as NSString).appendingPathComponent(item)
                var isDir: ObjCBool = false
                
                guard FileManager.default.fileExists(atPath: itemPath, isDirectory: &isDir),
                      isDir.boolValue else {
                    return nil
                }
                
                return IconCategory.fromFolder(itemPath)
            }.sorted { $0.name < $1.name }
            
            return categories
        } catch {
            print("无法获取分类目录：\(error.localizedDescription)")
            return []
        }
    }
    
    /// 获取分类总数
    var totalCategories: Int {
        categories.count
    }
    
    /// 获取所有图标的总数
    var totalIcons: Int {
        categories.reduce(0) { $0 + $1.iconCount }
    }
    
    /// 获取非空分类
    var nonEmptyCategories: [IconCategory] {
        categories.filter { !$0.isEmpty }
    }
    
    /// 获取空分类
    var emptyCategories: [IconCategory] {
        categories.filter { $0.isEmpty }
    }
}

// MARK: - 预览扩展
extension IconCategory {
    /// 预览用的示例分类
    static let preview = IconCategory(
        name: "Sample",
        iconCount: 5,
        iconIds: ["1", "2", "3", "4", "5"]
    )
    
    /// 预览用的示例分类列表
    static let previewList = [
        IconCategory(name: "Animals", iconCount: 10, iconIds: Array(1...10).map { String($0) }),
        IconCategory(name: "Food", iconCount: 8, iconIds: Array(1...8).map { String($0) }),
        IconCategory(name: "Objects", iconCount: 15, iconIds: Array(1...15).map { String($0) })
    ]
}
