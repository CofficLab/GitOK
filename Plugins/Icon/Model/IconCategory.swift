import Foundation
import SwiftUI

/**
 * 图标分类模型
 * 用于管理图标分类的数据结构和相关操作
 */
struct IconCategory: Identifiable, Hashable {
    /// 分类的唯一标识符
    let id = UUID()
    
    /// 分类文件夹URL
    let categoryURL: URL
    
    /// 分类名称（从URL动态计算）
    var name: String {
        categoryURL.lastPathComponent
    }
    
    /// 分类下的图标数量（动态计算）
    var iconCount: Int {
        iconIds.count
    }
    
    /// 分类下的所有图标ID（动态计算）
    var iconIds: [String] {
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: categoryURL.path)
            
            // 支持多种图标文件格式
            let supportedFormats = ["png", "svg", "jpg", "jpeg", "gif", "webp"]
            let iconFiles = files.filter { filename in
                let fileExtension = filename.lowercased()
                return supportedFormats.contains { format in
                    fileExtension.hasSuffix(".\(format)")
                }
            }
            
            // 使用文件名本身作为ID
            return iconFiles.compactMap { filename -> String? in
                let nameWithoutExt = (filename as NSString).deletingPathExtension
                return nameWithoutExt
            }.sorted()
        } catch {
            return []
        }
    }
    
    /// 分类的显示名称（用于UI显示）
    var displayName: String {
        name.uppercased()
    }
    
    /// 初始化方法
    /// - Parameter categoryURL: 分类文件夹URL
    init(categoryURL: URL) {
        self.categoryURL = categoryURL
    }
    
    /// 从文件夹路径创建分类
    /// - Parameter folderPath: 分类文件夹路径
    /// - Returns: 分类实例，如果路径无效则返回nil
    static func fromFolder(_ folderPath: String) -> IconCategory? {
        let url = URL(fileURLWithPath: folderPath)
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir),
              isDir.boolValue else {
            return nil
        }
        
        return IconCategory(categoryURL: url)
    }
    
    /// 获取指定ID的图标
    /// - Parameter iconId: 图标ID（支持数字ID和哈希文件名）
    /// - Returns: 图标Image，如果不存在则返回默认图标
    func getIcon(_ iconId: String) -> Image {
        guard iconIds.contains(iconId) else {
            return Image(systemName: "photo")
        }
        
        // 使用 IconAsset 来智能查找图标文件
        return IconAsset.getImage(categoryName: name, iconId: iconId)
    }
    
    /// 检查是否包含指定ID的图标
    /// - Parameter iconId: 图标ID（支持数字ID和哈希文件名）
    /// - Returns: 是否包含该图标
    func containsIcon(_ iconId: String) -> Bool {
        iconIds.contains(iconId)
    }
    
    /// 获取分类下的所有图标资源
    /// - Returns: IconAsset数组
    func getAllIconAssets() -> [IconAsset] {
        return iconIds.map { iconId in
            IconAsset(categoryName: name, iconId: iconId)
        }
    }
    
    /// 获取分类下的所有图标资源（异步版本，适用于大量图标）
    /// - Returns: IconAsset数组的异步结果
    func getAllIconAssetsAsync() async -> [IconAsset] {
        return await withTaskGroup(of: IconAsset.self) { group in
            for iconId in iconIds {
                group.addTask {
                    IconAsset(categoryName: self.name, iconId: iconId)
                }
            }
            
            var assets: [IconAsset] = []
            for await asset in group {
                assets.append(asset)
            }
            return assets.sorted { $0.iconId < $1.iconId }
        }
    }
    
    /// 获取指定分类下的所有图标ID（静态方法）
    /// - Parameter category: 分类名称
    /// - Returns: 图标ID数组（支持数字ID和哈希文件名）
    static func getIconIds(in category: String) -> [String] {
        guard let iconFolderURL = IconRepo.getIconFolderURL() else {
            return []
        }
        
        let categoryURL = iconFolderURL.appendingPathComponent(category)
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: categoryURL.path)
            
            // 支持多种图标文件格式
            let supportedFormats = ["png", "svg", "jpg", "jpeg", "gif", "webp"]
            
            // 过滤所有支持的图标文件格式并提取ID
            let iconIds = files.compactMap { filename -> String? in
                let fileExtension = filename.lowercased()
                guard supportedFormats.contains(where: { format in
                    fileExtension.hasSuffix(".\(format)")
                }) else { return nil }
                
                let nameWithoutExt = (filename as NSString).deletingPathExtension
                // 对于哈希文件名，直接使用原始文件名
                // 对于数字文件名，转换为字符串
                return nameWithoutExt
            }.sorted()
            
            return iconIds
        } catch {
            return []
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
