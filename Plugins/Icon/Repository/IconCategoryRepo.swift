import Foundation
import SwiftUI
import OSLog
import MagicCore

/**
 * 图标分类仓库
 * 负责读取和管理项目支持的所有候选图标分类
 * 使用单例模式确保全局唯一实例
 */
class IconCategoryRepo: ObservableObject, SuperLog {
    nonisolated static var emoji: String { "🎨" }
    
    /// 单例实例
    static let shared = IconCategoryRepo()
    
    /// 图标文件夹URL
    private let iconFolderURL: URL?
    
    /// 所有可用的图标分类
    @Published private(set) var categories: [IconCategory] = []
    
    /// 分类是否正在加载
    @Published private(set) var isLoading = false
    
    /// 私有初始化方法，确保单例模式
    private init() {
        // 直接初始化 iconFolderURL，避免在初始化过程中调用实例方法
        self.iconFolderURL = Self.findIconFolder()
        loadCategories()
    }
    
    /// 查找图标文件夹（静态方法，可以在初始化过程中调用）
    /// - Returns: 图标文件夹URL，如果找不到则返回nil
    private static func findIconFolder() -> URL? {
        // 首先尝试 Bundle 中的资源
        if let bundleURL = Bundle.main.url(forResource: "Icons", withExtension: nil) {
            print("IconCategoryRepo: 使用 Bundle 中的图标文件夹: \(bundleURL.path)")
            return bundleURL
        }
        
        // 如果 Bundle 中没有，尝试项目根目录下的 Resources/Icons
        let projectRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let resourcesIconsURL = projectRoot.appendingPathComponent("Resources").appendingPathComponent("Icons")
        if FileManager.default.fileExists(atPath: resourcesIconsURL.path) {
            print("IconCategoryRepo: 使用项目根目录下的图标文件夹: \(resourcesIconsURL.path)")
            return resourcesIconsURL
        }
        
        // 如果还是找不到，尝试从当前工作目录向上查找
        var currentURL = projectRoot
        while currentURL.path != "/" {
            let testURL = currentURL.appendingPathComponent("Resources").appendingPathComponent("Icons")
            if FileManager.default.fileExists(atPath: testURL.path) {
                print("IconCategoryRepo: 使用向上查找的图标文件夹: \(testURL.path)")
                return testURL
            }
            currentURL = currentURL.deletingLastPathComponent()
        }
        
        print("IconCategoryRepo: 无法找到图标文件夹")
        return nil
    }
    
    /// 获取图标文件夹URL（公共方法，供其他类使用）
    /// - Returns: 图标文件夹URL，如果找不到则返回nil
    static func getIconFolderURL() -> URL? {
        return findIconFolder()
    }
    
    /// 加载所有分类
    func loadCategories() {
        guard let iconFolderURL = iconFolderURL else {
            os_log(.error, "\(self.t)未找到图标文件夹")
            return
        }
        
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let newCategories = self?.scanCategories(from: iconFolderURL) ?? []
            
            DispatchQueue.main.async {
                self?.categories = newCategories
                self?.isLoading = false
                os_log("\(self?.t ?? "")✅ 加载了 \(newCategories.count) 个图标分类")
            }
        }
    }
    
    /// 扫描图标分类
    /// - Parameter folderURL: 图标文件夹URL
    /// - Returns: 分类数组
    private func scanCategories(from folderURL: URL) -> [IconCategory] {
        do {
            let items = try FileManager.default.contentsOfDirectory(atPath: folderURL.path)
            let categories = items.compactMap { item -> IconCategory? in
                let itemPath = (folderURL.path as NSString).appendingPathComponent(item)
                var isDir: ObjCBool = false
                
                guard FileManager.default.fileExists(atPath: itemPath, isDirectory: &isDir),
                      isDir.boolValue else {
                    return nil
                }
                
                return createCategory(from: itemPath, name: item)
            }.sorted { $0.name < $1.name }
            
            return categories
        } catch {
            os_log(.error, "\(self.t)无法扫描分类目录：\(error.localizedDescription)")
            return []
        }
    }
    
    /// 创建分类对象
    /// - Parameters:
    ///   - folderPath: 分类文件夹路径
    ///   - name: 分类名称
    /// - Returns: 分类实例
    private func createCategory(from folderPath: String, name: String) -> IconCategory? {
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
                name: name,
                iconCount: iconFiles.count,
                iconIds: iconIds
            )
        } catch {
            os_log(.error, "\(self.t)无法读取分类 \(name) 的文件：\(error.localizedDescription)")
            return nil
        }
    }
    
    /// 获取指定名称的分类
    /// - Parameter name: 分类名称
    /// - Returns: 分类实例，如果不存在则返回nil
    func getCategory(byName name: String) -> IconCategory? {
        categories.first { $0.name == name }
    }
    
    /// 获取指定分类下的图标数量
    /// - Parameter category: 分类名称
    /// - Returns: 图标数量
    func getIconCount(in category: String) -> Int {
        getCategory(byName: category)?.iconCount ?? 0
    }
    
    /// 获取指定分类下的所有图标ID
    /// - Parameter category: 分类名称
    /// - Returns: 图标ID数组（支持数字ID和哈希文件名）
    func getIconIds(in category: String) -> [String] {
        getCategory(byName: category)?.iconIds ?? []
    }
    
    /// 获取指定分类和ID的图标
    /// - Parameters:
    ///   - category: 分类名称
    ///   - iconId: 图标ID（支持数字ID和哈希文件名）
    /// - Returns: 图标Image
    func getImage(category: String, iconId: String) -> Image {
        // 使用 IconAsset 来智能查找图标文件
        return IconAsset.getImage(category: category, iconId: iconId)
    }
    
    /// 获取指定分类和ID的缩略图
    /// - Parameters:
    ///   - category: 分类名称
    ///   - iconId: 图标ID（支持数字ID和哈希文件名）
    /// - Returns: 缩略图Image
    func getThumbnail(category: String, iconId: String) -> Image {
        // 使用 IconAsset 来智能查找图标文件
        return IconAsset.getThumbnail(category: category, iconId: iconId)
    }
    
    /// 生成缩略图
    /// - Parameters:
    ///   - image: 原始图片
    ///   - size: 缩略图尺寸
    /// - Returns: 缩略图，如果生成失败则返回nil
    private func generateThumbnail(for image: NSImage, size: NSSize) -> NSImage? {
        let thumbnail = NSImage(size: size)
        thumbnail.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: size), 
                  from: NSRect(origin: .zero, size: image.size), 
                  operation: .copy, 
                  fraction: 1.0)
        thumbnail.unlockFocus()
        return thumbnail
    }
    
    /// 获取所有图标的总数
    var totalIcons: Int {
        categories.reduce(0) { $0 + $1.iconCount }
    }
    
    /// 获取分类总数
    var totalCategories: Int {
        categories.count
    }
    
    /// 获取非空分类
    var nonEmptyCategories: [IconCategory] {
        categories.filter { !$0.isEmpty }
    }
    
    /// 获取空分类
    var emptyCategories: [IconCategory] {
        categories.filter { $0.isEmpty }
    }
    
    /// 刷新分类列表
    func refreshCategories() {
        loadCategories()
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
