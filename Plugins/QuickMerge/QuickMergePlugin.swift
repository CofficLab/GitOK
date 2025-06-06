import MagicCore
import OSLog
import SwiftUI

class QuickMergePlugin: SuperPlugin, SuperLog {
    let emoji = "📣"
    var label: String = "QuickMerge"
    var icon: String = "folder.fill"
    var isTab: Bool = false

    func addDBView() -> AnyView {
        AnyView(EmptyView())
    }

    func addListView() -> AnyView {
        AnyView(EmptyView())
    }

    func addDetailView() -> AnyView {
        AnyView(GitDetail())
    }
    
    func addStatusBarTrailingView() -> AnyView {
        AnyView(TileQuickMerge())
    }

    func onInit() {
        os_log("\(self.t) onInit")
    }

    func onAppear() {
        os_log("\(self.t) onAppear")
    }

    func onDisappear() {
        os_log("\(self.t) onDisappear")
    }

    func onPlay() {
        os_log("\(self.t) onPlay")
    }

    func onPlayStateUpdate() {
        os_log("\(self.t) onPlayStateUpdate")
    }

    func onPlayAssetUpdate() {
        os_log("\(self.t) onPlayAssetUpdate")
    }
}
