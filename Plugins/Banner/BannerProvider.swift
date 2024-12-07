
import AVKit
import Combine
import Foundation
import MediaPlayer
import OSLog
import SwiftUI
import MagicKit

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
    }

    func setBanner(_ b: BannerModel) {
        if !Thread.isMainThread {
            assertionFailure("setBanner called from background thread")
        }

        self.banner = b
    }

    func setBanners(_ b: [BannerModel]) {
        self.banners = b
        if !banners.contains(self.banner) {
            self.banner = banners.first ?? .empty
        }
    }

    func setBanners(_ project: Project) {
        self.setBanners(try! project.getBanners())
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
