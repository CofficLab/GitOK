import Foundation
import SwiftUI
import Cocoa

class IconPng {
    static var iconFolderURL = Bundle.main.url(forResource: "Icons", withExtension: nil)
    
    // 获取所有分类目录
    static func getCategories() -> [String] {
        if let folderPath = iconFolderURL?.path {
            do {
                let items = try FileManager.default.contentsOfDirectory(atPath: folderPath)
                // 过滤出目录，排除文件
                let categories = items.filter { item in
                    let itemPath = (folderPath as NSString).appendingPathComponent(item)
                    var isDir: ObjCBool = false
                    FileManager.default.fileExists(atPath: itemPath, isDirectory: &isDir)
                    return isDir.boolValue
                }
                return categories.sorted()
            } catch {
                print("无法获取分类目录：\(error.localizedDescription)")
                return []
            }
        } else {
            print("未找到指定的引用文件夹")
            return []
        }
    }
    
    // 获取指定分类下的图标数量
    static func getIconCount(in category: String) -> Int {
        if let folderPath = iconFolderURL?.path {
            let categoryPath = (folderPath as NSString).appendingPathComponent(category)
            do {
                let files = try FileManager.default.contentsOfDirectory(atPath: categoryPath)
                // 只计算PNG文件
                let pngFiles = files.filter { $0.hasSuffix(".png") }
                return pngFiles.count
            } catch {
                print("无法获取分类 \(category) 中的文件数量：\(error.localizedDescription)")
                return 0
            }
        }
        return 0
    }
    
    // 获取指定分类下的所有图标ID
    static func getIconIds(in category: String) -> [Int] {
        if let folderPath = iconFolderURL?.path {
            let categoryPath = (folderPath as NSString).appendingPathComponent(category)
            do {
                let files = try FileManager.default.contentsOfDirectory(atPath: categoryPath)
                // 过滤PNG文件并提取数字ID
                let iconIds = files.compactMap { filename -> Int? in
                    guard filename.hasSuffix(".png") else { return nil }
                    let nameWithoutExt = (filename as NSString).deletingPathExtension
                    return Int(nameWithoutExt)
                }.sorted()
                return iconIds
            } catch {
                print("无法获取分类 \(category) 中的图标ID：\(error.localizedDescription)")
                return []
            }
        }
        return []
    }
    
    // 获取指定分类和ID的图标
    static func getImage(category: String, iconId: Int) -> Image {
        let url = iconFolderURL!.appendingPathComponent(category).appendingPathComponent("\(iconId).png")
        if let nsImage = NSImage(contentsOf: url) {
            return Image(nsImage: nsImage)
        } else {
            return Image(systemName: "plus")
        }
    }
    
    // 获取指定分类和ID的缩略图
    static func getThumbnail(category: String, iconId: Int) -> Image {
        let url = iconFolderURL!.appendingPathComponent(category).appendingPathComponent("\(iconId).png")
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
    
    // 兼容旧版本的方法
    static func getTotalCount() -> Int {
        let categories = getCategories()
        return categories.reduce(0) { total, category in
            total + getIconCount(in: category)
        }
    }
    
    static func getImage(_ iconId: Int) -> Image {
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
    
    static func getThumbnail(_ iconId: Int) -> Image {
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
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
