import Foundation
import SwiftUI
import Cocoa

class IconPng {
    static var iconFolderURL = Bundle.main.url(forResource: "Icons", withExtension: nil)
    
    static func getTotalCount() -> Int {
        if let folderPath = iconFolderURL?.path {
            do {
                let files = try FileManager.default.contentsOfDirectory(atPath: folderPath)
                return files.count
            } catch {
                print("无法获取引用文件夹中的文件数量：\(error.localizedDescription)")
                return 0
            }
        } else {
            print("未找到指定的引用文件夹")
            return 0
        }
    }
    
    static func getImage(_ iconId: Int) -> Image {
        let url = iconFolderURL!.appendingPathComponent("\(iconId).png")
        if let nsImage = NSImage(contentsOf: url) {
            let image = Image(nsImage: nsImage)
            return image
        } else {
            return Image(systemName: "plus")
        }
    }
    
    static func getThumbnial(_ iconId: Int) -> Image {
        let url = iconFolderURL!.appendingPathComponent("\(iconId).png")
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
            .hideTabPicker()
//            .hideProjectActions()
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
