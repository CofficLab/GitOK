import Foundation
import SwiftUI
import OSLog
import MagicCore

/**
 * APP本身带有的图标仓库
 * 负责读取和管理项目支持的所有候选图标分类
 * 使用单例模式确保全局唯一实例
 * 实现 IconSourceProtocol 协议以支持统一的图标来源管理
 */
class AppIconRepo: SuperLog, IconSourceProtocol {
    nonisolated static var emoji: String { "🎨" }
    
    /// 单例实例
    static let shared = AppIconRepo()
    
    /// 图标文件夹URL
    private let iconFolderURL: URL?
    
    /// 私有初始化方法，确保单例模式
    private init() {
        self.iconFolderURL = Self.findIconFolder()
    }
    
    // MARK: - IconSourceProtocol Implementation
    
    var sourceType: IconSourceType {
        return .local
    }
    
    var sourceName: String {
        return "本地图标库"
    }
    
    var isAvailable: Bool {
        get async {
            return iconFolderURL != nil
        }
    }
    
    /// 查找图标文件夹（静态方法，可以在初始化过程中调用）
    /// - Returns: 图标文件夹URL，如果找不到则返回nil
    private static func findIconFolder() -> URL? {
        if let bundleURL = Bundle.main.url(forResource: "Icons", withExtension: nil) {
            return bundleURL
        }
        
        print("IconCategoryRepo: 无法找到图标文件夹")
        return nil
    }
    
    /// 获取图标文件夹URL（公共方法，供其他类使用）
    /// - Returns: 图标文件夹URL，如果找不到则返回nil
    static func getIconFolderURL() -> URL? {
        return findIconFolder()
    }
    
    func getAllCategories() async -> [IconCategoryInfo] {
        guard let iconFolderURL = iconFolderURL else {
            os_log(.error, "\(self.t)未找到图标文件夹")
            return []
        }
        
        return scanCategories(from: iconFolderURL)
    }
    
    /// 获取所有分类（兼容旧接口）
    /// - Returns: IconCategory 分类数组
    func getAllIconCategories() -> [IconCategory] {
        guard let iconFolderURL = iconFolderURL else {
            os_log(.error, "\(self.t)未找到图标文件夹")
            return []
        }
        
        return scanIconCategories(from: iconFolderURL)
    }
    
    /// 扫描图标分类（返回 IconCategoryInfo）
    /// - Parameter folderURL: 图标文件夹URL
    /// - Returns: IconCategoryInfo 分类数组
    private func scanCategories(from folderURL: URL) -> [IconCategoryInfo] {
        do {
            let items = try FileManager.default.contentsOfDirectory(atPath: folderURL.path)
            let categories = items.compactMap { item -> IconCategoryInfo? in
                let categoryURL = folderURL.appendingPathComponent(item)
                var isDir: ObjCBool = false
                
                guard FileManager.default.fileExists(atPath: categoryURL.path, isDirectory: &isDir),
                      isDir.boolValue else {
                    return nil
                }
                
                // 计算图标数量
                let iconCount = getIconCount(in: categoryURL)
                
                return IconCategoryInfo(
                    id: item,
                    name: item,
                    iconCount: iconCount,
                    sourceType: .local,
                    sourceIdentifier: "app_bundle",
                    metadata: ["folderURL": categoryURL.path]
                )
            }.sorted { $0.name < $1.name }
            
            return categories
        } catch {
            os_log(.error, "\(self.t)无法扫描分类目录：\(error.localizedDescription)")
            return []
        }
    }
    
    /// 扫描图标分类（返回 IconCategory，兼容旧接口）
    /// - Parameter folderURL: 图标文件夹URL
    /// - Returns: IconCategory 分类数组
    private func scanIconCategories(from folderURL: URL) -> [IconCategory] {
        do {
            let items = try FileManager.default.contentsOfDirectory(atPath: folderURL.path)
            let categories = items.compactMap { item -> IconCategory? in
                let categoryURL = folderURL.appendingPathComponent(item)
                var isDir: ObjCBool = false
                
                guard FileManager.default.fileExists(atPath: categoryURL.path, isDirectory: &isDir),
                      isDir.boolValue else {
                    return nil
                }
                
                return IconCategory(categoryURL: categoryURL)
            }.sorted { $0.name < $1.name }
            
            return categories
        } catch {
            os_log(.error, "\(self.t)无法扫描分类目录：\(error.localizedDescription)")
            return []
        }
    }
    
    /// 计算分类下的图标数量
    /// - Parameter categoryURL: 分类文件夹URL
    /// - Returns: 图标数量
    private func getIconCount(in categoryURL: URL) -> Int {
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: categoryURL.path)
            let supportedFormats = ["png", "svg", "jpg", "jpeg", "gif", "webp"]
            return files.filter { filename in
                let fileExtension = filename.lowercased()
                return supportedFormats.contains { format in
                    fileExtension.hasSuffix(".\(format)")
                }
            }.count
        } catch {
            return 0
        }
    }
    
    func getCategory(byName name: String) async -> IconCategoryInfo? {
        let categories = await getAllCategories()
        return categories.first { $0.name == name }
    }
    
    func getIcons(for categoryId: String) async -> [IconAsset] {
        guard let iconFolderURL = iconFolderURL else { return [] }
        
        let categoryURL = iconFolderURL.appendingPathComponent(categoryId)
        
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: categoryURL.path)
            let supportedFormats = ["png", "svg", "jpg", "jpeg", "gif", "webp"]
            
            let iconFiles = files.filter { filename in
                let fileExtension = filename.lowercased()
                return supportedFormats.contains { format in
                    fileExtension.hasSuffix(".\(format)")
                }
            }
            
            return iconFiles.map { filename in
                let fileURL = categoryURL.appendingPathComponent(filename)
                return IconAsset(fileURL: fileURL)
            }
        } catch {
            os_log(.error, "\(self.t)无法读取分类图标：\(error.localizedDescription)")
            return []
        }
    }
    
    func getIconAsset(byId iconId: String) async -> IconAsset? {
        let categories = await getAllCategories()
        
        for category in categories {
            let icons = await getIcons(for: category.id)
            if let icon = icons.first(where: { $0.iconId == iconId }) {
                return icon
            }
        }
        
        return nil
    }
    
    /// 获取指定名称的分类（兼容旧接口）
    /// - Parameter name: 分类名称
    /// - Returns: IconCategory 实例，如果不存在则返回nil
    func getIconCategory(byName name: String) -> IconCategory? {
        return getAllIconCategories().first { $0.name == name }
    }
    
    /// 根据图标ID获取图标（兼容旧接口）
    /// - Parameter iconId: 图标ID
    /// - Returns: IconAsset实例，如果找不到则返回nil
    func getIconAssetSync(byId iconId: String) -> IconAsset? {
        let allCategories = getAllIconCategories()
        for category in allCategories {
            if category.iconIds.contains(iconId) {
                if let fileURL = Self.findIconFile(categoryName: category.name, iconId: iconId) {
                    return IconAsset(fileURL: fileURL)
                }
            }
        }
        return nil
    }
    
    /// 智能查找图标文件
    /// - Parameters:
    ///   - categoryName: 分类名称
    ///   - iconId: 图标ID（支持数字ID和哈希文件名）
    /// - Returns: 图标文件URL，如果找不到则返回nil
    static func findIconFile(categoryName: String, iconId: String) -> URL? {
        guard let iconFolderURL = getIconFolderURL() else { 
            return nil 
        }
        
        let categoryURL = iconFolderURL.appendingPathComponent(categoryName)
        
        // 对于哈希文件名，直接查找文件（不需要添加扩展名）
        // 首先检查是否已经是完整的文件名（包含扩展名）
        let directURL = categoryURL.appendingPathComponent(iconId)
        if FileManager.default.fileExists(atPath: directURL.path) {
            return directURL
        }
        
        // 如果直接查找失败，尝试添加扩展名查找
        // 优先查找PNG格式
        let pngURL = categoryURL.appendingPathComponent("\(iconId).png")
        if FileManager.default.fileExists(atPath: pngURL.path) {
            return pngURL
        }
        
        // 查找其他支持的格式
        let supportedFormats = ["svg", "jpg", "jpeg", "gif", "webp"]
        for format in supportedFormats {
            let url = categoryURL.appendingPathComponent("\(iconId).\(format)")
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }
        
        return nil
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideProjectActions()
            .hideSidebar()
            .hideTabPicker()
            .setInitialTab(IconPlugin.label)
    }
    .frame(width: 600)
    .frame(height: 800)
}

#Preview("App-Big Screen") {
    RootView {
        ContentLayout()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
