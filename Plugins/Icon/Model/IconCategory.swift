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
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: categoryURL.path)
            
            return files.count
        } catch {
            return 0
        }
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
    
    /// 查找指定图标ID的文件URL
    /// - Parameter iconId: 图标ID
    /// - Returns: 图标文件URL，如果找不到则返回nil
    private func findIconFileURL(for iconId: String) -> URL? {
        let supportedFormats = ["png", "svg", "jpg", "jpeg", "gif", "webp"]
        
        // 对于哈希文件名，直接查找文件（不需要添加扩展名）
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
        for format in supportedFormats {
            if format == "png" { continue } // 已经检查过了
            
            let url = categoryURL.appendingPathComponent("\(iconId).\(format)")
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }
        
        return nil
    }
    
    /// 获取分类下的所有图标资源
    /// - Returns: IconAsset数组
    func getAllIconAssets() -> [IconAsset] {
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
            
            // 直接创建IconAsset实例
            return iconFiles.map { filename in
                let fileURL = categoryURL.appendingPathComponent(filename)
                return IconAsset(fileURL: fileURL)
            }
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
