import SwiftUI
import MagicCore
import OSLog

class OpenRemotePlugin: SuperPlugin, SuperLog {
    let emoji = "🌐"
    var label: String = "OpenRemote"
    var icon: String = "safari"
    var isTab: Bool = false

    func addDBView() -> AnyView {
        AnyView(EmptyView())
    }

    func addDetailView() -> AnyView {
        AnyView(EmptyView())
    }

    func addToolBarLeadingView() -> AnyView {
        AnyView(BtnOpenRemoteView())
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
