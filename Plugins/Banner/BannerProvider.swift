
import AVKit
import Combine
import Foundation
import MediaPlayer
import OSLog
import SwiftUI
import MagicCore

@MainActor
class BannerProvider: NSObject, ObservableObject, SuperLog {
    @Published var banners: [BannerData] = []
    @Published var banner: BannerData = .empty

    var emoji = "🐘"
    
    /// Banner仓库实例
    private let bannerRepo = BannerRepo.shared

    // MARK: - Banner管理方法

    func appendBanner(_ b: BannerData) {
        if !Thread.isMainThread {
            assertionFailure("appendBanner called from background thread")
        }

        self.banners.append(b)
        self.setBanner(b)
    }

    func removeBanner(_ b: BannerData) {
        if !Thread.isMainThread {
            assertionFailure("removeBanner called from background thread")
        }

        do {
            try bannerRepo.deleteBanner(b)
            self.banners.removeAll(where: { $0 == b })
        } catch {
            os_log(.error, "\(self.emoji) 删除Banner失败: \(error.localizedDescription)")
        }
    }

    func setBanner(_ b: BannerData) {
        if !Thread.isMainThread {
            assertionFailure("setBanner called from background thread")
        }

        self.banner = b
    }

    func setBanners(_ b: [BannerData]) {
        if !Thread.isMainThread {
            assertionFailure("setBanners called from background thread")
        }

        self.banners = b
        if !banners.contains(self.banner) {
            self.banner = banners.first ?? .empty
        }
    }

    func setBanners(_ project: Project) {
        if !Thread.isMainThread {
            assertionFailure("setBanners called from background thread")
        }

        let bannerData = bannerRepo.getBanners(from: project)
        self.setBanners(bannerData)
    }
    
    // MARK: - 新增方法

    /// 创建新的Banner
    /// - Parameters:
    ///   - project: 所属项目
    ///   - title: Banner标题
    func createBanner(in project: Project, title: String = "New Banner") {
        do {
            let newBanner = try bannerRepo.createBanner(in: project, title: title)
            self.appendBanner(newBanner)
        } catch {
            os_log(.error, "\(self.emoji) 创建Banner失败: \(error.localizedDescription)")
        }
    }
    
    /// 保存Banner
    /// - Parameter banner: 要保存的Banner
    func saveBanner(_ banner: BannerData) {
        do {
            try bannerRepo.saveBanner(banner)
        } catch {
            os_log(.error, "\(self.emoji) 保存Banner失败: \(error.localizedDescription)")
        }
    }
    
    /// 更新Banner
    /// - Parameters:
    ///   - banner: 原Banner
    ///   - updates: 更新数据
    func updateBanner(_ banner: BannerData, with updates: BannerDataUpdate) {
        do {
            let updatedBanner = try bannerRepo.updateBanner(banner, with: updates)
            
            // 更新本地数据
            if let index = banners.firstIndex(where: { $0.id == banner.id }) {
                banners[index] = updatedBanner
            }
            
            if self.banner.id == banner.id {
                self.banner = updatedBanner
            }
        } catch {
            os_log(.error, "\(self.emoji) 更新Banner失败: \(error.localizedDescription)")
        }
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

