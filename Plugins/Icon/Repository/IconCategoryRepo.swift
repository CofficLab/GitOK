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
        self.iconFolderURL = Bundle.main.url(forResource: "Icons", withExtension: nil)
        loadCategories()
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
            let pngFiles = files.filter { $0.hasSuffix(".png") }
            let iconIds = pngFiles.compactMap { filename -> Int? in
                let nameWithoutExt = (filename as NSString).deletingPathExtension
                return Int(nameWithoutExt)
            }.sorted()
            
            return IconCategory(
                name: name,
                iconCount: pngFiles.count,
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
    /// - Returns: 图标ID数组
    func getIconIds(in category: String) -> [Int] {
        getCategory(byName: category)?.iconIds ?? []
    }
    
    /// 获取指定分类和ID的图标
    /// - Parameters:
    ///   - category: 分类名称
    ///   - iconId: 图标ID
    /// - Returns: 图标Image
    func getImage(category: String, iconId: Int) -> Image {
        guard let iconFolderURL = iconFolderURL else {
            return Image(systemName: "photo")
        }
        
        let url = iconFolderURL.appendingPathComponent(category).appendingPathComponent("\(iconId).png")
        if let nsImage = NSImage(contentsOf: url) {
            return Image(nsImage: nsImage)
        } else {
            return Image(systemName: "photo")
        }
    }
    
    /// 获取指定分类和ID的缩略图
    /// - Parameters:
    ///   - category: 分类名称
    ///   - iconId: 图标ID
    /// - Returns: 缩略图Image
    func getThumbnail(category: String, iconId: Int) -> Image {
        guard let iconFolderURL = iconFolderURL else {
            return Image(systemName: "photo")
        }
        
        let url = iconFolderURL.appendingPathComponent(category).appendingPathComponent("\(iconId).png")
        if let image = NSImage(contentsOf: url) {
            if let thumbnail = generateThumbnail(for: image, size: NSSize(width: 80, height: 80)) {
                return Image(nsImage: thumbnail)
            } else {
                return Image(systemName: "photo")
            }
        } else {
            return Image(systemName: "photo")
        }
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
    .frame(height: 600)
}

#Preview("App-Big Screen") {
    RootView {
        ContentLayout()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
