import MagicCore
import OSLog
import SwiftUI

class GitPlugin: SuperPlugin, SuperLog {
    let emoji = "📣"
    var label: String = "Git"
    var icon: String = "folder.fill"
    var isTab: Bool = true

    func addDBView() -> AnyView {
        AnyView(EmptyView())
    }

    func addListView() -> AnyView {
        AnyView(CommitList().environmentObject(GitProvider.shared))
    }

    func addDetailView() -> AnyView {
        AnyView(GitDetail()
            .environmentObject(GitProvider.shared)
        )
    }

    func addToolBarTrailingView() -> AnyView {
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

#Preview {
    RootView {
        ContentView()
            .hideSidebar()
    }
    .frame(width: 800)
    .frame(height: 800)
}

#Preview("App-Big Screen") {
    RootView {
        ContentView()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
