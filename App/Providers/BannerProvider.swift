
import AVKit
import Combine
import Foundation
import MediaPlayer
import OSLog
import SwiftUI

class BannerProvider: NSObject, ObservableObject, SuperLog {
    @Published var bannerURL: URL = .null

    var emoji = "🐘"

    func setBannerURL(_ u: URL) {
        self.bannerURL = u
    }

    func getBanner() throws -> BannerModel {
        try BannerModel.fromFile(bannerURL)
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
