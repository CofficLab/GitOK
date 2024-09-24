
import AVKit
import Combine
import Foundation
import MediaPlayer
import OSLog
import SwiftUI

class BannerProvider: NSObject, ObservableObject, SuperLog {
    @Published var banner: BannerModel = .empty

    var emoji = "🐘"
        
    func setBanner(_ b: BannerModel, reason: String) {
        let verbose = true
        
        if verbose {
            os_log("\(self.t)Set Banner(\(reason))")
            os_log("  ➡️ \(b.title)")
        }
        
        self.banner = b
        self.banner.save()
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
