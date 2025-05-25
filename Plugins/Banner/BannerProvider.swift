
import AVKit
import Combine
import Foundation
import MediaPlayer
import OSLog
import SwiftUI
import MagicCore

@MainActor
class BannerProvider: NSObject, ObservableObject, SuperLog {
    @Published var banners: [BannerModel] = []
    @Published var banner: BannerModel = .empty

    var emoji = "🐘"

    func appendBanner(_ b: BannerModel) {
        if !Thread.isMainThread {
            assertionFailure("appendBanner called from background thread")
        }

        self.banners.append(b)
        self.setBanner(b)
    }

    func removeBanner(_ b: BannerModel) {
        if !Thread.isMainThread {
            assertionFailure("removeBanner called from background thread")
        }

        b.delete()
        self.banners.removeAll(where: { $0 == b })
    }

    func setBanner(_ b: BannerModel) {
        if !Thread.isMainThread {
            assertionFailure("setBanner called from background thread")
        }

        self.banner = b
    }

    func setBanners(_ b: [BannerModel]) {
        if !Thread.isMainThread {
            assertionFailure("appendBanner called from background thread")
        }

        self.banners = b
        if !banners.contains(self.banner) {
            self.banner = banners.first ?? .empty
        }
    }

    func setBanners(_ project: Project) {
        if !Thread.isMainThread {
            assertionFailure("appendBanner called from background thread")
        }

        self.setBanners(try! project.getBanners())
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
