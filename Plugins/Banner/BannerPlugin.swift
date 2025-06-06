import MagicCore
import OSLog
import SwiftUI

class BannerPlugin: SuperPlugin, SuperLog {
    let emoji = "📣"
    var label: String = "Banner"
    var icon: String = "camera"
    var isTab: Bool = true

    func addDBView() -> AnyView {
        AnyView(EmptyView())
    }

    func addListView(tab: String) -> AnyView {
        if tab == self.label {
            AnyView(BannerList())
        } else {
            AnyView(EmptyView())
        }
    }

    func addDetailView() -> AnyView {
        AnyView(BannerDetail())
    }
    
    func addStatusBarTrailingView() -> AnyView {
        AnyView(EmptyView())
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
