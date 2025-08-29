import Foundation
import OSLog
import SwiftUI
import MagicCore

/**
 * 项目图标仓库（当前项目内）
 * 扫描当前项目路径下的 .gitok/images 目录，提供图标分类与图标资源
 */
class ProjectImagesRepo: IconSourceProtocol, SuperLog {
    nonisolated static var emoji: String { "📁" }
    static let shared = ProjectImagesRepo()
    
    // 唯一标识与名称
    var sourceIdentifier: String { "project_images" }
    var sourceName: String { "项目图标库" }
    
    // 支持增删
    var supportsMutations: Bool { true }
    
    // 基础配置
    private let imagesRelativePath = ".gitok/images"
    private let supportedFormats = ["png", "svg", "jpg", "jpeg", "gif", "webp"]
    
    private init() {}
    
    // MARK: - Helpers
    private func currentProjectImagesURL() -> URL? {
        let state = StateRepo()
        guard !state.projectPath.isEmpty else { return nil }
        let base = URL(fileURLWithPath: state.projectPath)
        return base.appendingPathComponent(imagesRelativePath)
    }
    
    private func listImageFiles(in directory: URL) -> [URL] {
        do {
            let items = try FileManager.default.contentsOfDirectory(atPath: directory.path)
            return items.compactMap { name in
                let lower = name.lowercased()
                guard supportedFormats.contains(where: { lower.hasSuffix(".\($0)") }) else { return nil }
                return directory.appendingPathComponent(name)
            }
        } catch {
            return []
        }
    }
    
    // MARK: - Mutations (Add/Delete)
    
    /// 向项目图标库添加一张图片（同步实现）
    func addImage(data: Data, filename: String) -> Bool {
        guard let imagesURL = currentProjectImagesURL() else { return false }
        var isDir: ObjCBool = false
        if !FileManager.default.fileExists(atPath: imagesURL.path, isDirectory: &isDir) {
            do { try FileManager.default.createDirectory(at: imagesURL, withIntermediateDirectories: true) } catch { return false }
        }
        let lower = filename.lowercased()
        guard supportedFormats.contains(where: { lower.hasSuffix(".\($0)") }) else { return false }
        let target = imagesURL.appendingPathComponent(filename)
        do {
            try data.write(to: target, options: .atomic)
            print("[ProjectImagesRepo] addImage saved: \(target.path)")
            return true
        } catch {
            print("[ProjectImagesRepo] addImage error: \(error)")
            return false
        }
    }
    
    /// 从项目图标库删除一张图片（同步实现）
    func deleteImage(filename: String) -> Bool {
        guard let imagesURL = currentProjectImagesURL() else { return false }
        let fileURL = imagesURL.appendingPathComponent(filename)
        do {
            try FileManager.default.removeItem(at: fileURL)
            print("[ProjectImagesRepo] deleteImage removed: \(fileURL.path)")
            return true
        } catch {
            print("[ProjectImagesRepo] deleteImage error: \(error)")
            return false
        }
    }
    
    // 异步桥接（协议默认提供，但本处提供具化实现以复用同步逻辑）
    func addImage(data: Data, filename: String) async -> Bool { await addImage(data: data, filename: filename) }
    func deleteImage(filename: String) async -> Bool { await deleteImage(filename: filename) }
    
    // MARK: - IconSourceProtocol
    
    var isAvailable: Bool {
        get async {
            guard let imagesURL = currentProjectImagesURL() else { return false }
            var isDir: ObjCBool = false
            return FileManager.default.fileExists(atPath: imagesURL.path, isDirectory: &isDir) && isDir.boolValue
        }
    }
    
    func getAllCategories() async -> [IconCategoryInfo] {
        guard let imagesURL = currentProjectImagesURL() else { return [] }
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: imagesURL.path, isDirectory: &isDir), isDir.boolValue else { return [] }
        
        // 最小实现：提供一个聚合分类 "Project Images"
        let iconFiles = listImageFiles(in: imagesURL)
        let category = IconCategoryInfo(
            id: "project_images",
            name: "Project Images",
            iconCount: iconFiles.count,
            sourceIdentifier: sourceIdentifier,
            metadata: ["folder": imagesURL.path]
        )
        return [category]
    }
    
    func getIcons(for categoryId: String) async -> [IconAsset] {
        guard categoryId == "project_images", let imagesURL = currentProjectImagesURL() else { return [] }
        let files = listImageFiles(in: imagesURL)
        return files.map { fileURL in IconAsset(fileURL: fileURL) }
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
    .frame(width: 800)
    .frame(height: 1200)
}
