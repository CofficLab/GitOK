import Foundation
import OSLog
import SwiftUI
import MagicKit

/**
 * 项目图标仓库（当前项目内）
 * 扫描当前项目路径下的 .gitok/images 目录，提供图标分类与图标资源
 */
class ProjectImagesRepo: IconSourceProtocol, SuperLog {
    nonisolated static var emoji: String { "📁" }
    static let shared = ProjectImagesRepo()
    
    // 唯一标识与名称
    var sourceIdentifier: String { "project_images" }
    var sourceName: String { "项目图库" }
    
    // 支持增删
    var supportsMutations: Bool { true }
    
    // 不支持分类（聚合展示）
    var supportsCategories: Bool { false }
    
    // 基础配置
    private let imagesRelativePath = ".gitok/images"
    
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
            return IconFileRules.imageFileURLs(in: directory, entries: items)
        } catch {
            return []
        }
    }
    
    // MARK: - Mutations (Add/Delete)
    
    /// 向项目图标库添加一张图片
    func addImage(data: Data, filename: String) async -> Bool {
        guard let imagesURL = currentProjectImagesURL() else { return false }
        var isDir: ObjCBool = false
        if !FileManager.default.fileExists(atPath: imagesURL.path, isDirectory: &isDir) {
            do { try FileManager.default.createDirectory(at: imagesURL, withIntermediateDirectories: true) } catch { return false }
        }
        guard IconFileRules.isSupportedImageFile(filename) else { return false }
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
    
    /// 从项目图标库删除一张图片
    func deleteImage(filename: String) async -> Bool {
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
    
    // MARK: - IconSourceProtocol
    
    var isAvailable: Bool {
        get async {
            guard let imagesURL = currentProjectImagesURL() else { return false }
            var isDir: ObjCBool = false
            return FileManager.default.fileExists(atPath: imagesURL.path, isDirectory: &isDir) && isDir.boolValue
        }
    }
    
    func getAllCategories(reason: String) async -> [IconCategory] { [] }
    
    func getIcons(for categoryId: String) async -> [IconAsset] { await getAllIcons() }

    func getAllIcons() async -> [IconAsset] {
        guard let imagesURL = currentProjectImagesURL() else { return [] }
        let files = listImageFiles(in: imagesURL)
        return files.map { fileURL in IconAsset(fileURL: fileURL) }
    }
    
    func getIconAsset(byId iconId: String) async -> IconAsset? {
        // 不支持分类：直接在所有文件中查找
        let icons = await getAllIcons()
        // 支持匹配去扩展名的文件名以及完整文件名
        if let found = icons.first(where: { asset in
            if asset.iconId == iconId { return true }
            if let name = asset.fileURL?.lastPathComponent {
                return name == iconId || name.hasPrefix(iconId + ".")
            }
            return false
        }) {
            return found
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
            .setInitialTab("Icon")
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 800)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .setInitialTab("Icon")
            .hideSidebar()
    }
    .frame(width: 800)
    .frame(height: 1200)
}
