import MagicKit
import OSLog
import SwiftUI

class SmartProjectPlugin: SuperPlugin, SuperLog {
    let emoji = "📣"
    var label: String = "SmartProject"
    var icon: String = "folder.fill"
    var isTab: Bool = false

    func addDBView() -> AnyView {
        AnyView(EmptyView())
    }

    func addListView() -> AnyView {
        AnyView(CommitList())
    }

    func addDetailView() -> AnyView {
        AnyView(GitDetail())
    }
    
    func addToolBarLeadingView() -> AnyView {
        AnyView(TileProject())
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
