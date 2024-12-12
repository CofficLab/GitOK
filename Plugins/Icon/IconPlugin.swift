import MagicKit
import OSLog
import SwiftUI

class IconPlugin: SuperPlugin, SuperLog {
    let emoji = "📣"
    var label: String = "Icon"
    var icon: String = "globe.europe.africa"
    var isTab: Bool = true

    func addDBView() -> AnyView {
        AnyView(EmptyView())
    }

    func addListView() -> AnyView {
        AnyView(IconList())
    }

    func addDetailView() -> AnyView {
        AnyView(DetailIcon())
    }
    
    func addToolBarTrailingView() -> AnyView {
        AnyView(EmptyView())
    }

    func onInit() {
        os_log("\(self.t) onInit")
    }

    func onAppear(project: Project?) {
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
