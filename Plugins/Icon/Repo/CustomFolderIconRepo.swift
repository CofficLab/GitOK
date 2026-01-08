import Foundation
import SwiftUI
import OSLog


/**
 * 自定义文件夹图标仓库
 * 支持用户指定的本地文件夹作为图标来源
 * 演示如何轻松添加新的图标来源
 */
class CustomFolderIconRepo: IconSourceProtocol {
    func getAllIcons() async -> [IconAsset] {
        []
    }
    
    /// 自定义来源唯一标识
    let sourceIdentifier: String
    
    /// 自定义来源显示名称
    let sourceName: String
    
    /// 根文件夹 URL
    private let customFolderURL: URL?
    
    init(identifier: String, name: String, folderURL: URL?) {
        self.sourceIdentifier = identifier
        self.sourceName = name
        self.customFolderURL = folderURL
    }
    
    var isAvailable: Bool {
        get async {
            guard let url = customFolderURL else { return false }
            var isDirectory: ObjCBool = false
            let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
            return exists && isDirectory.boolValue
        }
    }
    
    func getAllCategories(reason: String) async -> [IconCategory] {
        guard let folderURL = customFolderURL,
              await isAvailable else {
            return []
        }
        
        do {
            let items = try FileManager.default.contentsOfDirectory(atPath: folderURL.path)
            let categories = items.compactMap { item -> IconCategory? in
                let categoryURL = folderURL.appendingPathComponent(item)
                var isDir: ObjCBool = false
                
                guard FileManager.default.fileExists(atPath: categoryURL.path, isDirectory: &isDir),
                      isDir.boolValue else {
                    return nil
                }
                
                // 计算图标数量
                let iconCount = getIconCount(in: categoryURL)
                
                return IconCategory(
                    id: item,
                    name: item,
                    iconCount: iconCount,
                    sourceIdentifier: self.sourceIdentifier,
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
    
    func getIcons(for categoryId: String) async -> [IconAsset] {
        guard let folderURL = customFolderURL else { return [] }
        let categoryURL = folderURL.appendingPathComponent(categoryId)
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
            return []
        }
    }
    
    func getIconAsset(byId iconId: String) async -> IconAsset? {
        let categories = await getAllCategories(reason: "get_icon_by_id")
        for category in categories {
            let icons = await getIcons(for: category.id)
            if let icon = icons.first(where: { $0.iconId == iconId }) {
                return icon
            }
        }
        return nil
    }
    
    func getCategory(byName name: String) async -> IconCategory? {
        let categories = await getAllCategories(reason: "get_category_by_name")
        return categories.first { $0.name == name }
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
