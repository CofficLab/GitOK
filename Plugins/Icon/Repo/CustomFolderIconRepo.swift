import Foundation
import SwiftUI
import OSLog
import MagicCore

/**
 * 自定义文件夹图标仓库
 * 支持用户指定的本地文件夹作为图标来源
 * 演示如何轻松添加新的图标来源
 */
class CustomFolderIconRepo: IconSourceProtocol {
    /// 自定义文件夹路径
    private let customFolderURL: URL?
    
    /// 来源标识符
    private let identifier: String
    
    /// 初始化方法
    /// - Parameters:
    ///   - folderPath: 自定义文件夹路径
    ///   - identifier: 来源标识符（用于区分不同的自定义文件夹）
    init(folderPath: String, identifier: String = "custom_folder") {
        self.customFolderURL = URL(fileURLWithPath: folderPath)
        self.identifier = identifier
    }
    
    // MARK: - IconSourceProtocol Implementation
    
    var sourceType: IconSourceType {
        return .custom
    }
    
    var sourceName: String {
        return "自定义文件夹 (\(customFolderURL?.lastPathComponent ?? "未知"))"
    }
    
    var isAvailable: Bool {
        get async {
            guard let folderURL = customFolderURL else { return false }
            
            var isDirectory: ObjCBool = false
            let exists = FileManager.default.fileExists(atPath: folderURL.path, isDirectory: &isDirectory)
            return exists && isDirectory.boolValue
        }
    }
    
    func getAllCategories() async -> [IconCategoryInfo] {
        guard let folderURL = customFolderURL,
              await isAvailable else {
            return []
        }
        
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
                    sourceType: .custom,
                    sourceIdentifier: identifier,
                    metadata: [
                        "folderURL": categoryURL.path,
                        "parentFolder": folderURL.path
                    ]
                )
            }.sorted { $0.name < $1.name }
            
            os_log(.info, "扫描到 \(categories.count) 个自定义分类")
            return categories
        } catch {
            os_log(.error, "无法扫描自定义文件夹：\(error.localizedDescription)")
            return []
        }
    }
    
    func getIcons(for categoryId: String) async -> [IconAsset] {
        guard let folderURL = customFolderURL,
              await isAvailable else {
            return []
        }
        
        let categoryURL = folderURL.appendingPathComponent(categoryId)
        
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: categoryURL.path)
            let supportedFormats = ["png", "svg", "jpg", "jpeg", "gif", "webp", "ico"]
            
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
            os_log(.error, "无法读取自定义分类图标：\(error.localizedDescription)")
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
    
    func getCategory(byName name: String) async -> IconCategoryInfo? {
        let categories = await getAllCategories()
        return categories.first { $0.name == name }
    }
    
    // MARK: - Private Methods
    
    /// 计算分类下的图标数量
    /// - Parameter categoryURL: 分类文件夹URL
    /// - Returns: 图标数量
    private func getIconCount(in categoryURL: URL) -> Int {
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: categoryURL.path)
            let supportedFormats = ["png", "svg", "jpg", "jpeg", "gif", "webp", "ico"]
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
