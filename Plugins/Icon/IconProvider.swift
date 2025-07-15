import AVKit
import Combine
import Foundation
import MagicCore
import MediaPlayer
import OSLog
import SwiftUI

class IconProvider: NSObject, ObservableObject, SuperLog {
    @Published var snapshotTapped: Bool = false
    @Published private(set) var currentModel: IconModel? = nil

    static var emoji = "🍒"

    // 当前从候选列表中选中的图标ID
    @Published var iconId: Int = 0

    override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleIconDidSave),
            name: .iconDidSave,
            object: nil)

        NotificationCenter.default.addObserver(
            self, selector: #selector(handleIconDidDelete),
            name: .iconDidDelete,
            object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleIconDidSave(_ notification: Notification) {
        let iconPath = self.currentModel?.path
        if let iconPath = iconPath {
            let newModel = try? IconModel.fromJSONFile(URL(fileURLWithPath: iconPath))
            self.updateCurrentModel(newModel: newModel, reason: "iconDidSave event")
        }
    }

    @objc private func handleIconDidDelete(_ notification: Notification) {
        let path = notification.userInfo?["path"] as? String
        if let path = path, path == self.currentModel?.path {
            self.currentModel = nil
        }
    }

    func updateCurrentModel(newModel: IconModel?, reason: String) {
        os_log("\(self.t)Update Current Model(\(reason)) ➡️ \(newModel?.title ?? "nil")")

        self.currentModel = newModel
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
