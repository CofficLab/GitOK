import BannerCoreKit
import Foundation
import GitOKCoreKit
import GitOKSupportKit
import OSLog
import ProjectRulesKit
import SwiftUI

/**
    Banner仓库管理器
    统一管理Banner相关的数据操作，提供清晰的数据访问接口
    类似于IconRepo的架构模式，支持多种Banner数据来源
**/
final class BannerRepo: SuperLog, @unchecked Sendable {
    nonisolated static var emoji: String { "📣" }

    /// 单例实例
    static let shared = BannerRepo()

    /// 私有初始化方法，确保单例模式
    private init() {
    }

    // MARK: - 项目Banner管理

    /// Banner存储目录路径（相对于项目根目录）
    static let bannerStoragePath = ".gitok/banners"

    /// 获取项目下的所有Banner
    /// - Parameter projectURL: 项目根目录
    /// - Returns: 该项目下的所有BannerData数组
    func getBanners(from projectURL: URL) -> [BannerFile] {
        return getBannerData(from: projectURL)
    }

    func getBannersAsync(from projectURL: URL) async -> [BannerFile] {
        await Task.detached(priority: .userInitiated) {
            self.getBanners(from: projectURL)
        }.value
    }

    /// 根据ID查找Banner
    /// - Parameters:
    ///   - id: Banner的ID
    ///   - projectURL: 所属项目根目录
    /// - Returns: 找到的BannerFile，如果未找到则返回nil
    func getBanner(by id: String, from projectURL: URL) -> BannerFile? {
        let banners = getBanners(from: projectURL)
        return banners.first { $0.id == id }
    }

    func getBannerAsync(by id: String, from projectURL: URL) async -> BannerFile? {
        await Task.detached(priority: .userInitiated) {
            self.getBanner(by: id, from: projectURL)
        }.value
    }

    /// 从项目目录获取所有Banner模型
    /// - Parameter projectURL: 项目根目录
    /// - Returns: 该project下的所有BannerData数组
    private func getBannerData(from projectURL: URL) -> [BannerFile] {
        let bannerDirectoryURL = BannerStorageRules.bannerDirectoryURL(
            projectPath: projectURL.path,
            storagePath: Self.bannerStoragePath
        )

        return BannerRepositoryIndex.loadModels(
            from: bannerDirectoryURL,
            load: { [weak self] fileURL in
                self?.tryLoadBannerData(from: fileURL, projectURL: projectURL)
            },
            sort: { $0.id < $1.id }
        )
    }

    /// 尝试加载Banner模型
    /// - Parameters:
    ///   - fileURL: Banner配置文件URL
    ///   - projectURL: 所属项目根目录
    /// - Returns: Banner模型，如果加载失败则返回nil
    private func tryLoadBannerData(from fileURL: URL, projectURL: URL) -> BannerFile? {
        do {
            let data = try Data(contentsOf: fileURL)
            var bannerData = try JSONDecoder().decode(BannerFile.self, from: data)
            bannerData.path = fileURL.path
            bannerData.projectURL = projectURL
            return bannerData
        } catch {
            os_log(.error, "\(Self.emoji) 加载Banner失败 \(fileURL.lastPathComponent): \(error.localizedDescription)")
            return nil
        }
    }

    /// 创建新的Banner
    /// - Parameters:
    ///   - projectURL: 所属项目根目录
    ///   - title: Banner标题
    /// - Returns: 新创建的BannerData
    func createBanner(in projectURL: URL, title: String = "New Banner") throws -> BannerFile {
        let bannerDirectoryURL = BannerStorageRules.bannerDirectoryURL(
            projectPath: projectURL.path,
            storagePath: Self.bannerStoragePath
        )

        // 确保Banner目录存在
        try FileManager.default.createDirectory(at: bannerDirectoryURL, withIntermediateDirectories: true, attributes: nil)

        // 生成唯一的文件名
        let fileName = BannerStorageRules.newBannerFileName(now: Date())
        let fileURL = bannerDirectoryURL.appendingPathComponent(fileName)

        // 创建新的BannerData
        let bannerData = BannerFile(
            path: fileURL.path,
            projectURL: projectURL
        )

        // 保存到文件
        try saveBannerToFile(bannerData, at: fileURL)

        // 发送创建通知
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .bannerAdded,
                object: bannerData,
                userInfo: ["id": bannerData.id]
            )
        }

        return bannerData
    }

    /// 保存Banner数据
    /// - Parameter banner: 要保存的Banner数据
    func saveBanner(_ banner: BannerFile) throws {
        let fileURL = URL(fileURLWithPath: banner.path)
        try saveBannerToFile(banner, at: fileURL)

        // 发送保存通知
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .bannerDidSave, object: banner)
        }
    }

    /// 将Banner数据保存到文件
    /// - Parameters:
    ///   - banner: Banner数据
    ///   - fileURL: 文件URL
    private func saveBannerToFile(_ banner: BannerFile, at fileURL: URL) throws {
        let data = try JSONEncoder().encode(banner)
        try data.write(to: fileURL)
    }

    /// 删除Banner
    /// - Parameter banner: 要删除的Banner数据
    func deleteBanner(_ banner: BannerFile) throws {
        let fileURL = URL(fileURLWithPath: banner.path)

        // 删除文件
        try FileManager.default.removeItem(at: fileURL)

        // 发送删除通知
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .bannerDidDelete, object: banner, userInfo: ["id": banner.id])
        }
    }

    /// 更新Banner数据
    /// - Parameters:
    ///   - banner: 原Banner数据
    ///   - updates: 更新的数据
    /// - Returns: 更新后的BannerData
    func updateBanner(_ banner: BannerFile, with updates: BannerDataUpdate) throws -> BannerFile {
        let updatedBanner = banner

        // 保存更新后的数据
        try saveBanner(updatedBanner)

        return updatedBanner
    }
}

/// Banner数据更新结构
struct BannerDataUpdate {
    var title: String?
    var subTitle: String?
    var features: [String]?
    var imageId: String?
    var backgroundId: String?
    var device: String?
    var opacity: Double?
}
