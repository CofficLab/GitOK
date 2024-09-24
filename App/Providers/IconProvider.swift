import AVKit
import Combine
import Foundation
import MediaPlayer
import OSLog
import SwiftUI

class IconProvider: NSObject, ObservableObject, SuperLog {
    @Published var icon: IconModel = .empty

    var emoji = "🌬️"
        
    func setIcon(_ i: IconModel, reason: String) {
        let verbose = false
        
        if verbose {
            os_log("\(self.t)Set Icon(\(reason))")
            os_log("  ➡️ \(i.title)")
        }
        
        self.icon = i
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
