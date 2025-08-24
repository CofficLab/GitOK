import Foundation
import SwiftUI

/**
 * 图标分类模型
 * 用于管理图标分类的数据结构和相关操作
 */
struct IconCategory: Identifiable, Hashable {
    /// 分类的唯一标识符
    var id: URL { categoryURL }
    
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

// MARK: - 统一图标分类结构体

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

#Preview("App - Small Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 800)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
