
import AVKit
import Combine
import Foundation
import MediaPlayer
import OSLog
import SwiftUI
import MagicKit

class BannerProvider: NSObject, ObservableObject, SuperLog {
    @Published var bannerURL: URL?

    var emoji = "🐘"

    func setBannerURL(_ u: URL) {
        self.bannerURL = u
    }

    func getBanner() throws -> BannerModel? {
        guard let bannerURL = bannerURL else {
            return nil
        }

        return try BannerModel.fromFile(bannerURL)
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
