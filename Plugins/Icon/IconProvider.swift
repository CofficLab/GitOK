import AVKit
import Combine
import Foundation
import MediaPlayer
import OSLog
import SwiftUI
import MagicCore

class IconProvider: NSObject, ObservableObject, SuperLog {
    @Published var iconURL: URL?
    @Published var snapshotTapped: Bool = false
    // 当前从候选列表中选中的图标ID
    @Published var iconId: Int = 0

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

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideProjectActions()
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
