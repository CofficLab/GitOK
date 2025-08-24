import Foundation
import SwiftUI
import Cocoa

/**
 * 图标来源类型
 */
enum IconSource {
    case local
    case remote
}

/**
 * 图标资源工具类
 * 负责处理IconCategory下的具体图标操作
 * 支持多种文件格式（PNG、SVG等），自动检测和智能查找
 * 同时支持本地和远程图标的统一管理
 */
class IconAsset: Identifiable {
    /// 图标文件URL
    let fileURL: URL
    
    /// 稳定的ID（使用文件路径作为唯一标识）
    var id: String { fileURL.path }
    
    /// 图标所属分类名称（从URL计算）
    var categoryName: String {
        fileURL.deletingLastPathComponent().lastPathComponent
    }
    
    /// 图标ID（从URL计算）
    var iconId: String {
        fileURL.deletingPathExtension().lastPathComponent
    }
    
    /// 初始化方法
    /// - Parameter fileURL: 图标文件URL
    init(fileURL: URL) {
        self.fileURL = fileURL
    }
    
    /// 获取图标图片
    /// - Returns: SwiftUI Image
    func getImage() -> Image {
        return loadImage()
    }
    
    /// 获取图标缩略图
    /// - Returns: SwiftUI Image
    func getThumbnail() -> Image {
        return loadThumbnail()
    }
    
    /// 检查图标文件是否存在
    /// - Returns: 是否存在
    func exists() -> Bool {
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
    
    // MARK: - 私有实例方法
    
    /// 加载图片（支持多种格式）
    /// - Returns: SwiftUI Image
    private func loadImage() -> Image {
        let fileExtension = fileURL.pathExtension.lowercased()
        
        switch fileExtension {
        case "svg":
            return loadSVGImage()
        case "png", "jpg", "jpeg", "gif", "webp":
            return loadRasterImage()
        default:
            return Image(systemName: "plus")
        }
    }
    
    /// 加载SVG图片
    /// - Returns: SwiftUI Image
    private func loadSVGImage() -> Image {
        // macOS原生支持SVG格式，可以直接使用NSImage加载
        if let nsImage = NSImage(contentsOf: fileURL) {
            return Image(nsImage: nsImage)
        } else {
            return Image(systemName: "doc.text.image")
        }
    }
    
    /// 加载光栅图片（PNG、JPG等）
    /// - Returns: SwiftUI Image
    private func loadRasterImage() -> Image {
        if let nsImage = NSImage(contentsOf: fileURL) {
            return Image(nsImage: nsImage)
        } else {
            return Image(systemName: "plus")
        }
    }
    
    /// 加载缩略图（支持多种格式）
    /// - Returns: SwiftUI Image
    private func loadThumbnail() -> Image {
        let fileExtension = fileURL.pathExtension.lowercased()
        
        switch fileExtension {
        case "svg":
            // SVG缩略图可以直接使用原图，因为它是矢量图形
            return loadSVGImage()
        case "png", "jpg", "jpeg", "gif", "webp":
            return loadRasterThumbnail()
        default:
            return Image(systemName: "plus")
        }
    }
    
    /// 加载光栅图片缩略图
    /// - Returns: SwiftUI Image
    private func loadRasterThumbnail() -> Image {
        if let image = NSImage(contentsOf: fileURL) {
            if let thumbnail = generateThumbnail(for: image) {
                return Image(nsImage: thumbnail)
            } else {
                return Image(systemName: "plus")
            }
        } else {
            return Image(systemName: "plus")
        }
    }
    
    /// 生成缩略图
    /// - Parameter image: 原始图片
    /// - Returns: 缩略图
    private func generateThumbnail(for image: NSImage) -> NSImage? {
        let thumbnailSize = NSSize(width: 50, height: 50)
        
        let thumbnail = NSImage(size: thumbnailSize)
        thumbnail.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: thumbnailSize), from: NSRect(origin: .zero, size: image.size), operation: .copy, fraction: 1.0)
        thumbnail.unlockFocus()
        
        return thumbnail
    }
}

// MARK: - 统一图标结构体

/**
 * 统一图标
 * 整合本地和远程图标数据
 */
struct UnifiedIcon: Identifiable, Hashable {
    let id: String
    let name: String
    let source: IconSource
    let localIcon: IconAsset?
    let remoteIcon: RemoteIcon?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: UnifiedIcon, rhs: UnifiedIcon) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - 远程图标相关结构体

/**
 * 远程图标
 * 对应网络API返回的图标数据结构
 */
struct RemoteIcon: Identifiable, Hashable {
    let id: String
    let name: String
    let path: String
    let category: String
    let fullPath: String
    let size: Int
    let modified: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: RemoteIcon, rhs: RemoteIcon) -> Bool {
        lhs.id == rhs.id
    }
}

/**
 * 远程图标分类
 * 对应网络API返回的分类数据结构
 */
struct RemoteIconCategory: Identifiable, Hashable {
    let id: String
    let name: String
    let displayName: String
    let iconCount: Int
    let remoteIconIds: [IconData]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: RemoteIconCategory, rhs: RemoteIconCategory) -> Bool {
        lhs.id == rhs.id
    }
}

/**
 * 图标清单数据结构
 * 对应API返回的JSON数据结构
 */
struct IconManifest: Codable {
    let generatedAt: String
    let totalIcons: Int
    let totalCategories: Int
    let categories: [CategoryData]
    let iconsByCategory: [String: [IconData]]
    
    enum CodingKeys: String, CodingKey {
        case generatedAt
        case totalIcons
        case totalCategories
        case categories
        case iconsByCategory
    }
}

/**
 * 分类数据结构
 * 对应API返回的分类数据
 */
struct CategoryData: Codable {
    let id: String
    let name: String
    let count: Int
}

/**
 * 图标数据结构
 * 对应API返回的图标数据
 */
struct IconData: Codable {
    let name: String
    let path: String
    let category: String
    let fullPath: String
    let size: Int
    let modified: String
}

// MARK: - 错误类型

/**
 * 远程图标仓库错误类型
 */
enum RemoteIconError: Error, LocalizedError {
    case invalidURL
    case networkError
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .networkError:
            return "网络请求失败"
        case .decodingError:
            return "数据解析失败"
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
    .frame(height: 800)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .frame(width: 1200)
            .frame(height: 1200)
    }
}
