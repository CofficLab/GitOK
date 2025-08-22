import Foundation
import SwiftUI
import Cocoa

/**
 * 图标资源工具类
 * 负责处理IconCategory下的具体图标操作
 * 支持多种文件格式（PNG、SVG等），自动检测和智能查找
 */
class IconAsset {
    /// 获取图标文件夹URL（委托给IconCategoryRepo）
    /// - Returns: 图标文件夹URL，如果找不到则返回nil
    private static var iconFolderURL: URL? {
        return IconCategoryRepo.getIconFolderURL()
    }
    
    /// 支持的图标文件格式
    private static let supportedFormats = ["png", "svg", "jpg", "jpeg", "gif", "webp"]
    
    /// 默认图标文件格式（优先查找）
    private static let defaultFormat = "png"
    
    // 获取所有分类目录（委托给IconCategoryRepo）
    static func getCategories() -> [String] {
        return IconCategoryRepo.getCategoryNames()
    }
    
    // 获取指定分类下的所有图标ID（委托给IconCategory）
    static func getIconIds(in category: String) -> [String] {
        return IconCategory.getIconIds(in: category)
    }
    
    // 获取指定分类和ID的图标
    static func getImage(category: String, iconId: String) -> Image {
        if let imageURL = findIconFile(category: category, iconId: iconId) {
            return loadImage(from: imageURL)
        } else {
            return Image(systemName: "plus")
        }
    }
    
    /// 智能查找图标文件
    /// - Parameters:
    ///   - category: 分类名称
    ///   - iconId: 图标ID（支持数字ID和哈希文件名）
    /// - Returns: 图标文件URL，如果找不到则返回nil
    private static func findIconFile(category: String, iconId: String) -> URL? {
        print("🔍 IconAsset.findIconFile: 开始查找 - 分类: \(category), ID: \(iconId)")
        
        guard let iconFolderURL = iconFolderURL else { 
            print("🔍 IconAsset.findIconFile: iconFolderURL 为 nil")
            return nil 
        }
        
        print("🔍 IconAsset.findIconFile: 图标文件夹路径: \(iconFolderURL.path)")
        let categoryPath = iconFolderURL.appendingPathComponent(category)
        print("🔍 IconAsset.findIconFile: 分类路径: \(categoryPath.path)")
        
        // 对于哈希文件名，直接查找文件（不需要添加扩展名）
        // 首先检查是否已经是完整的文件名（包含扩展名）
        let directURL = categoryPath.appendingPathComponent(iconId)
        if FileManager.default.fileExists(atPath: directURL.path) {
            print("🔍 IconAsset.findIconFile: 找到直接文件: \(directURL.path)")
            return directURL
        }
        
        // 如果直接查找失败，尝试添加扩展名查找
        // 优先查找默认格式
        let defaultURL = categoryPath.appendingPathComponent("\(iconId).\(defaultFormat)")
        print("🔍 IconAsset.findIconFile: 检查默认格式: \(defaultURL.path)")
        if FileManager.default.fileExists(atPath: defaultURL.path) {
            print("🔍 IconAsset.findIconFile: 找到默认格式文件")
            return defaultURL
        }
        
        // 如果默认格式不存在，查找其他支持的格式
        for format in supportedFormats {
            if format == defaultFormat { continue } // 已经检查过了
            
            let url = categoryPath.appendingPathComponent("\(iconId).\(format)")
            print("🔍 IconAsset.findIconFile: 检查格式 \(format): \(url.path)")
            if FileManager.default.fileExists(atPath: url.path) {
                print("🔍 IconAsset.findIconFile: 找到格式 \(format) 文件")
                return url
            }
        }
        
        print("🔍 IconAsset.findIconFile: 未找到任何格式的文件")
        return nil
    }
    
    /// 加载图片（支持多种格式）
    /// - Parameter url: 图片文件URL
    /// - Returns: SwiftUI Image
    private static func loadImage(from url: URL) -> Image {
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "svg":
            return loadSVGImage(from: url)
        case "png", "jpg", "jpeg", "gif", "webp":
            return loadRasterImage(from: url)
        default:
            return Image(systemName: "plus")
        }
    }
    
    /// 加载SVG图片
    /// - Parameter url: SVG文件URL
    /// - Returns: SwiftUI Image
    private static func loadSVGImage(from url: URL) -> Image {
        // macOS原生支持SVG格式，可以直接使用NSImage加载
        if let nsImage = NSImage(contentsOf: url) {
            return Image(nsImage: nsImage)
        } else {
            print("无法加载SVG文件：\(url.path)")
            return Image(systemName: "doc.text.image")
        }
    }
    
    /// 加载光栅图片（PNG、JPG等）
    /// - Parameter url: 图片文件URL
    /// - Returns: SwiftUI Image
    private static func loadRasterImage(from url: URL) -> Image {
        if let nsImage = NSImage(contentsOf: url) {
            return Image(nsImage: nsImage)
        } else {
            return Image(systemName: "plus")
        }
    }
    
    // 获取指定分类和ID的缩略图
    static func getThumbnail(category: String, iconId: String) -> Image {
        print("🖼️ IconAsset.getThumbnail: 开始查找图标 - 分类: \(category), ID: \(iconId)")
        if let imageURL = findIconFile(category: category, iconId: iconId) {
            print("🖼️ IconAsset.getThumbnail: 找到图标文件: \(imageURL.path)")
            return loadThumbnail(from: imageURL)
        } else {
            print("🖼️ IconAsset.getThumbnail: 未找到图标文件 - 分类: \(category), ID: \(iconId)")
            return Image(systemName: "plus")
        }
    }
    
    /// 加载缩略图（支持多种格式）
    /// - Parameter url: 图片文件URL
    /// - Returns: SwiftUI Image
    private static func loadThumbnail(from url: URL) -> Image {
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "svg":
            // SVG缩略图可以直接使用原图，因为它是矢量图形
            return loadSVGImage(from: url)
        case "png", "jpg", "jpeg", "gif", "webp":
            return loadRasterThumbnail(from: url)
        default:
            return Image(systemName: "plus")
        }
    }
    
    /// 加载光栅图片缩略图
    /// - Parameter url: 图片文件URL
    /// - Returns: SwiftUI Image
    private static func loadRasterThumbnail(from url: URL) -> Image {
        if let image = NSImage(contentsOf: url) {
            if let thumbnail = generateThumbnail(for: image, size: NSSize(width: 80, height: 80)) {
                return Image(nsImage: thumbnail)
            } else {
                print("无法生成缩略图")
                return Image(systemName: "plus")
            }
        } else {
            print("无法加载图片")
            return Image(systemName: "plus")
        }
    }
    
    static func getImage(_ iconId: String) -> Image {
        // 在所有分类中查找图标
        let categories = getCategories()
        for category in categories {
            let iconIds = getIconIds(in: category)
            if iconIds.contains(iconId) {
                return getImage(category: category, iconId: iconId)
            }
        }
        return Image(systemName: "plus")
    }
    
    static func getThumbnail(_ iconId: String) -> Image {
        // 在所有分类中查找图标
        let categories = getCategories()
        for category in categories {
            let iconIds = getIconIds(in: category)
            if iconIds.contains(iconId) {
                return getThumbnail(category: category, iconId: iconId)
            }
        }
        return Image(systemName: "plus")
    }

    static func generateThumbnail(for image: NSImage, size: NSSize) -> NSImage? {
        let thumbnailSize = NSSize(width: 50, height: 50)
        
        let thumbnail = NSImage(size: thumbnailSize)
        thumbnail.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: thumbnailSize), from: NSRect(origin: .zero, size: image.size), operation: .copy, fraction: 1.0)
        thumbnail.unlockFocus()
        
        return thumbnail
    }
    
    /// 获取图标文件信息
    /// - Parameters:
    ///   - category: 分类名称
    ///   - iconId: 图标ID（支持数字ID和哈希文件名）
    /// - Returns: 图标文件信息字典
    static func getIconFileInfo(category: String, iconId: String) -> [String: Any]? {
        guard let fileURL = findIconFile(category: category, iconId: iconId) else { return nil }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            let creationDate = attributes[.creationDate] as? Date
            let modificationDate = attributes[.modificationDate] as? Date
            
            return [
                "url": fileURL,
                "path": fileURL.path,
                "filename": fileURL.lastPathComponent,
                "extension": fileURL.pathExtension.lowercased(),
                "fileSize": fileSize,
                "creationDate": creationDate as Any,
                "modificationDate": modificationDate as Any
            ]
        } catch {
            print("无法获取文件信息：\(error.localizedDescription)")
            return nil
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
