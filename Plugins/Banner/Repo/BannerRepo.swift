import Foundation
import MagicCore
import OSLog
import SwiftUI

/**
    Banner仓库管理器
    统一管理Banner相关的数据操作，提供清晰的数据访问接口
    类似于IconRepo的架构模式，支持多种Banner数据来源
**/
class BannerRepo: SuperLog {
    nonisolated static var emoji: String { "📣" }

    /// 单例实例
    static let shared = BannerRepo()

    /// 私有初始化方法，确保单例模式
    private init() {
    }
    
    // MARK: - 项目Banner管理
    
    /// 获取项目下的所有Banner
    /// - Parameter project: Project对象
    /// - Returns: 该项目下的所有BannerData数组
    func getBanners(from project: Project) -> [BannerData] {
        return ProjectBannerRepo.getBannerData(from: project)
    }
    
    /// 创建新的Banner
    /// - Parameters:
    ///   - project: 所属项目
    ///   - title: Banner标题
    /// - Returns: 新创建的BannerData
    func createBanner(in project: Project, title: String = "New Banner") throws -> BannerData {
        return try ProjectBannerRepo.createBanner(in: project, title: title)
    }
    
    /// 保存Banner数据
    /// - Parameter banner: 要保存的Banner数据
    func saveBanner(_ banner: BannerData) throws {
        try ProjectBannerRepo.saveBanner(banner)
    }
    
    /// 删除Banner
    /// - Parameter banner: 要删除的Banner数据
    func deleteBanner(_ banner: BannerData) throws {
        try ProjectBannerRepo.deleteBanner(banner)
    }
    
    /// 更新Banner数据
    /// - Parameters:
    ///   - banner: 原Banner数据
    ///   - updates: 更新的数据
    /// - Returns: 更新后的BannerData
    func updateBanner(_ banner: BannerData, with updates: BannerDataUpdate) throws -> BannerData {
        return try ProjectBannerRepo.updateBanner(banner, with: updates)
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

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(BannerPlugin.label)
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(BannerPlugin.label)
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
