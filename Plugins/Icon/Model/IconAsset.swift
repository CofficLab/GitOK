import Foundation
import SwiftUI
import Cocoa

/**
 * 图标资源工具类
 * 负责处理IconCategory下的具体图标操作
 * 支持多种文件格式（PNG、SVG等），自动检测和智能查找
 */
class IconAsset: Identifiable {
    /// 唯一标识符
    let id = UUID()
    
    /// 图标文件URL
    let fileURL: URL
    
    /// 图标所属分类名称（从URL计算）
    var categoryName: String {
        fileURL.deletingLastPathComponent().lastPathComponent
    }
    
    /// 图标ID（从URL计算）
    var iconId: String {
        let filename = fileURL.deletingPathExtension().lastPathComponent
        // 尝试转换为数字，如果失败则使用原始文件名
        if let numericId = Int(filename) {
            return String(numericId)
        } else {
            // 哈希文件名，直接使用
            return filename
        }
    }
    
    /// 图标文件信息（延迟计算）
    lazy var fileInfo: [String: Any]? = {
        Self.getIconFileInfo(categoryName: categoryName, iconId: iconId)
    }()
    
    /// 初始化方法
    /// - Parameter fileURL: 图标文件URL
    init(fileURL: URL) {
        self.fileURL = fileURL
    }
    
    /// 获取图标图片
    /// - Returns: SwiftUI Image
    func getImage() -> Image {
        return Self.loadImage(from: fileURL)
    }
    
    /// 获取图标缩略图
    /// - Returns: SwiftUI Image
    func getThumbnail() -> Image {
        return Self.loadThumbnail(from: fileURL)
    }
    
    /// 检查图标文件是否存在
    /// - Returns: 是否存在
    func exists() -> Bool {
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
    
    // MARK: - 静态方法
    
    /// 支持的图标文件格式
    private static let supportedFormats = ["png", "svg", "jpg", "jpeg", "gif", "webp"]
    
    /// 默认图标文件格式（优先查找）
    private static let defaultFormat = "png"
    
    // 获取指定分类和ID的图标
    static func getImage(categoryName: String, iconId: String) -> Image {
        if let imageURL = IconRepo.findIconFile(categoryName: categoryName, iconId: iconId) {
            return loadImage(from: imageURL)
        } else {
            return Image(systemName: "plus")
        }
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
    static func getThumbnail(categoryName: String, iconId: String) -> Image {
        if let imageURL = IconRepo.findIconFile(categoryName: categoryName, iconId: iconId) {
            return loadThumbnail(from: imageURL)
        } else {
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
                return Image(systemName: "plus")
            }
        } else {
            return Image(systemName: "plus")
        }
    }
    
    static func getImage(_ iconId: String) -> Image {
        // 在所有分类中查找图标
        let allCategories = IconRepo.shared.getAllCategories()
        
        for category in allCategories {
            if category.iconIds.contains(iconId) {
                return getImage(categoryName: category.name, iconId: iconId)
            }
        }
        
        return Image(systemName: "plus")
    }
    
    static func getThumbnail(_ iconId: String) -> Image {
        // 在所有分类中查找图标
        let allCategories = IconRepo.shared.getAllCategories()
        
        for category in allCategories {
            if category.iconIds.contains(iconId) {
                return getThumbnail(categoryName: category.name, iconId: iconId)
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
    ///   - categoryName: 分类名称
    ///   - iconId: 图标ID
    /// - Returns: 图标文件信息字典
    static func getIconFileInfo(categoryName: String, iconId: String) -> [String: Any]? {
        guard let fileURL = IconRepo.findIconFile(categoryName: categoryName, iconId: iconId) else { return nil }
        
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
            .frame(width: 1200)
            .frame(height: 1200)
    }
}
