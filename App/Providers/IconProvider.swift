import AVKit
import Combine
import Foundation
import MediaPlayer
import OSLog
import SwiftUI
import MagicKit

class IconProvider: NSObject, ObservableObject, SuperLog {
    @Published var iconURL: URL?

    let emoji = "🍒"
        
    func setIconURL(_ i: URL, reason: String) {
        let verbose = true

        if verbose {
            os_log(.debug, "\(self.t)Set Icon URL(\(reason)) ➡️ \(i)")
        }

        self.iconURL = i
    }

    func getIcon() throws -> IconModel? {
        guard let iconURL = iconURL else {
            return nil
        }
        
        return try IconModel.fromJSONFile(iconURL)
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
