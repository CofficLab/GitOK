import Foundation
import SwiftUI

/**
 * 图标分类模型
 * 用于管理图标分类的数据结构和相关操作
 * 支持本地和远程分类的统一管理
 */
struct IconCategory: Identifiable, Hashable {
    /// 分类的唯一标识符
    var id: URL { categoryURL }
    
    /// 分类文件夹URL（本地分类）
    let categoryURL: URL
    
    /// 分类来源类型
    let source: IconSource
    
    /// 远程分类数据（仅远程分类有值）
    let remoteCategory: RemoteIconCategory?
    
    /// 分类名称（从URL动态计算或从远程数据获取）
    var name: String {
        switch source {
        case .local:
            return categoryURL.lastPathComponent
        case .remote:
            return remoteCategory?.name ?? ""
        }
    }
    
    /// 分类下的图标数量（动态计算或从远程数据获取）
    var iconCount: Int {
        switch source {
        case .local:
            do {
                let files = try FileManager.default.contentsOfDirectory(atPath: categoryURL.path)
                return files.count
            } catch {
                return 0
            }
        case .remote:
            return remoteCategory?.iconCount ?? 0
        }
    }
    
    /// 分类下的所有图标ID（动态计算或从远程数据获取）
    var iconIds: [String] {
        switch source {
        case .local:
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
        case .remote:
            return remoteCategory?.remoteIconIds.map { $0.name } ?? []
        }
    }
    
    /// 分类的显示名称（用于UI显示）
    var displayName: String {
        switch source {
        case .local:
            return name.uppercased()
        case .remote:
            return remoteCategory?.displayName ?? name.uppercased()
        }
    }
    
    /// 本地分类初始化方法
    /// - Parameter categoryURL: 分类文件夹URL
    init(categoryURL: URL) {
        self.categoryURL = categoryURL
        self.source = .local
        self.remoteCategory = nil
    }
    
    /// 远程分类初始化方法
    /// - Parameter remoteCategory: 远程分类数据
    init(remoteCategory: RemoteIconCategory) {
        // 为远程分类创建一个虚拟的URL
        let virtualURL = URL(string: "remote://\(remoteCategory.id)") ?? URL(string: "https://gitok.coffic.cn/\(remoteCategory.id)")!
        self.categoryURL = virtualURL
        self.source = .remote
        self.remoteCategory = remoteCategory
    }
    
    /// 获取分类下的所有图标资源
    /// - Returns: IconAsset数组
    func getAllIconAssets() async -> [IconAsset] {
        switch source {
        case .local:
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
        case .remote:
            return await IconRepo.shared.getIcons(for: self)
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout().setInitialTab(IconPlugin.label)
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 800)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout().setInitialTab(IconPlugin.label)
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
