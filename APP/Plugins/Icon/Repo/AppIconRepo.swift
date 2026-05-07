import Foundation
import MagicKit
import OSLog
import SwiftUI

/**
 * 本地图标仓库
 * 负责读取和管理应用内置的图标资源
 * 实现 IconSourceProtocol 协议，提供统一的图标来源接口
 */
class AppIconRepo: SuperLog, IconSourceProtocol {
    func getAllIcons() async -> [IconAsset] {
        []
    }
    
    nonisolated static var emoji: String { "🎨" }

    /// 单例实例
    static let shared = AppIconRepo()

    /// 图标文件夹URL
    private let iconFolderURL: URL?
    
    /// 来源唯一标识
    var sourceIdentifier: String { "app_bundle" }

    /// 来源名称（用于显示）
    var sourceName: String { "本地图标库" }

    /// 私有初始化方法，确保单例模式
    private init() {
        self.iconFolderURL = Self.findIconFolder()
    }

    // MARK: - IconSourceProtocol Implementation

    var isAvailable: Bool {
        get async {
            iconFolderURL != nil
        }
    }

    /// 查找图标文件夹（静态方法，可以在初始化过程中调用）
    /// - Returns: 图标文件夹URL，如果找不到则返回nil
    private static func findIconFolder() -> URL? {
        if let bundleURL = Bundle.main.url(forResource: "Icons", withExtension: nil) {
            return bundleURL
        }

        print("IconCategoryRepo: 无法找到图标文件夹")
        return nil
    }

    /// 获取图标文件夹URL（公共方法，供其他类使用）
    /// - Returns: 图标文件夹URL，如果找不到则返回nil
    static func getIconFolderURL() -> URL? {
        return findIconFolder()
    }

    func getAllCategories(reason: String) async throws -> [IconCategory] {
        guard let iconFolderURL = iconFolderURL else {
            os_log(.error, "\(self.t)未找到图标文件夹")
            throw RemoteIconError.networkError
        }

        return scanCategories(from: iconFolderURL)
    }

    /// 扫描图标分类
    /// - Parameter folderURL: 图标文件夹URL
    /// - Returns: IconCategoryInfo 分类数组
    private func scanCategories(from folderURL: URL) -> [IconCategory] {
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
                    metadata: ["folderURL": categoryURL.path]
                )
            }.sorted { $0.name < $1.name }

            return categories
        } catch {
            os_log(.error, "\(self.t)无法扫描分类目录：\(error.localizedDescription)")
            return []
        }
    }

    /// 计算分类下的图标数量
    /// - Parameter categoryURL: 分类文件夹URL
    /// - Returns: 图标数量
    private func getIconCount(in categoryURL: URL) -> Int {
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: categoryURL.path)
            return IconFileRules.iconCount(in: files)
        } catch {
            return 0
        }
    }

    func getCategory(byName name: String) async throws -> IconCategory? {
        let categories = try await getAllCategories(reason: "get_category_by_name")
        return categories.first { $0.name == name }
    }

    func getIcons(for categoryId: String) async -> [IconAsset] {
        guard let iconFolderURL = iconFolderURL else { return [] }

        let categoryURL = iconFolderURL.appendingPathComponent(categoryId)

        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: categoryURL.path)
            let iconFiles = files.filter(IconFileRules.isSupportedImageFile)

            return iconFiles.map { filename in
                let fileURL = categoryURL.appendingPathComponent(filename)
                return IconAsset(fileURL: fileURL)
            }
        } catch {
            os_log(.error, "\(self.t)无法读取分类图标：\(error.localizedDescription)")
            return []
        }
    }

    func getIconAsset(byId iconId: String) async throws -> IconAsset? {
        let categories = try await getAllCategories(reason: "get_icon_by_id")

        for category in categories {
            let icons = await getIcons(for: category.id)
            if let icon = icons.first(where: { $0.iconId == iconId }) {
                return icon
            }
        }

        return nil
    }

    /// 智能查找图标文件
    /// - Parameters:
    ///   - categoryName: 分类名称
    ///   - iconId: 图标ID（支持数字ID和哈希文件名）
    /// - Returns: 图标文件URL，如果找不到则返回nil
    static func findIconFile(categoryName: String, iconId: String) -> URL? {
        guard let iconFolderURL = getIconFolderURL() else {
            return nil
        }

        let categoryURL = iconFolderURL.appendingPathComponent(categoryName)

        for candidate in IconFileRules.preferredLookupCandidates(for: iconId) {
            let url = categoryURL.appendingPathComponent(candidate)
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }

        return nil
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideProjectActions()
            .hideSidebar()
            .hideTabPicker()
            .setInitialTab("Icon")
    }
    .frame(width: 600)
    .frame(height: 800)
}

#Preview("App-Big Screen") {
    RootView {
        ContentLayout()
            .hideProjectActions()
            .hideTabPicker()
            .setInitialTab("Icon")
    }
    .frame(width: 800)
    .frame(height: 1200)
}
