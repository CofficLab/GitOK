import SwiftUI
import MagicKit
import OSLog

class BannerPlugin: SuperPlugin, SuperLog {
    let emoji = "📣"
    var label: String = ""
    
    func addDBView() -> AnyView {
        AnyView(EmptyView())
    }

    func addListView() -> AnyView {
        AnyView(BannerList())
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
