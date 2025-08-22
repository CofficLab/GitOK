import Foundation
import OSLog
import SwiftData
import SwiftUI
import AppKit
import MagicCore


class GeneratedIcon: SuperLog {
    static var dir: String = ".gitok/images"
    
    let emoji = "🎨"
    
    var id: String
    
    init(id: String) {
        self.id = id
    }
    
    func getImageURL(_ projectURL: URL) -> URL {
        return projectURL.appendingPathComponent(Self.dir).appendingPathComponent(id)
    }

    func getImage(_ projectURL: URL) -> Image {
        if let nsImage = NSImage(contentsOf: getImageURL(projectURL)) {
            return Image(nsImage: nsImage)
        } else {
            return Image(systemName: "photo")
        }
    }
    
    static func fromImageId(_ imageId: String) -> GeneratedIcon {
        return GeneratedIcon(id: imageId)
    }

    static func removeImage(_ id: String, projectURL: URL) throws {
        let imagesFolder = projectURL.appendingPathComponent(Self.dir)
        let imageURL = imagesFolder.appendingPathComponent(id)

        try imageURL.delete()
    }
    
    static func saveImage(_ url: URL, projectURL: URL) throws -> String {
        os_log("SaveImage to project -> \(projectURL.relativeString)")

        let ext = url.pathExtension
        let fileName = "\(Date.nowCompact).\(ext)"
        let imagesFolder = projectURL.appendingPathComponent(Self.dir)
        let storeURL = imagesFolder.appendingPathComponent(fileName)

        os_log("  ➡️ \(url.relativeString)")
        os_log("  ➡️ \(storeURL.relativeString)")

        do {
            // 确保images目录存在
            try FileManager.default.createDirectory(at: imagesFolder, withIntermediateDirectories: true, attributes: nil)

            // 将文件复制到新位置
            try FileManager.default.copyItem(at: url, to: storeURL)
            return fileName
        } catch let e {
            os_log(.error, "SaveImage -> \(e.localizedDescription)")
            os_log(.error, "  ⚠️ \(e)")

            throw e
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
