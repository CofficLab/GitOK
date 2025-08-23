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
        self.iconFolderURL = Self.findIconFolder()
        loadCategories()
    }
    
    /// 查找图标文件夹（静态方法，可以在初始化过程中调用）
    /// - Returns: 图标文件夹URL，如果找不到则返回nil
    private static func findIconFolder() -> URL? {
        if let bundleURL = Bundle.main.url(forResource: "Icons", withExtension: nil) {
            print("IconCategoryRepo: 使用 Bundle 中的图标文件夹: \(bundleURL.path)")
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
    
    /// 获取所有分类名称（静态方法，供其他类使用）
    /// - Returns: 分类名称数组
    static func getCategoryNames() -> [String] {
        guard let iconFolderURL = getIconFolderURL() else {
            print("IconCategoryRepo.getCategoryNames: 未找到图标文件夹")
            return []
        }
        
        do {
            let items = try FileManager.default.contentsOfDirectory(atPath: iconFolderURL.path)
            print("IconCategoryRepo.getCategoryNames: 找到项目: \(items)")
            
            // 过滤出目录，排除文件
            let categories = items.filter { item in
                let itemPath = (iconFolderURL.path as NSString).appendingPathComponent(item)
                var isDir: ObjCBool = false
                FileManager.default.fileExists(atPath: itemPath, isDirectory: &isDir)
                return isDir.boolValue
            }
            
            print("IconCategoryRepo.getCategoryNames: 过滤后的分类: \(categories)")
            return categories.sorted()
        } catch {
            print("IconCategoryRepo.getCategoryNames: 无法获取分类目录：\(error.localizedDescription)")
            return []
        }
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
                
                return IconCategory(folderPath: itemPath)
            }.sorted { $0.name < $1.name }
            
            return categories
        } catch {
            os_log(.error, "\(self.t)无法扫描分类目录：\(error.localizedDescription)")
            return []
        }
    }
    
    /// 获取指定名称的分类
    /// - Parameter name: 分类名称
    /// - Returns: 分类实例，如果不存在则返回nil
    func getCategory(byName name: String) -> IconCategory? {
        categories.first { $0.name == name }
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
