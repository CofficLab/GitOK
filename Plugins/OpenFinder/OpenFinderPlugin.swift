import SwiftUI
import MagicCore
import OSLog

class OpenFinderPlugin: SuperPlugin, SuperLog {
    let emoji = "📂"
    var label: String = "OpenFinder"
    var icon: String = "folder"
    var isTab: Bool = false

    func addDBView() -> AnyView {
        AnyView(EmptyView())
    }

    func addListView() -> AnyView {
        AnyView(EmptyView())
    }

    func addDetailView() -> AnyView {
        AnyView(EmptyView())
    }

    func addToolBarLeadingView() -> AnyView {
        AnyView(BtnOpenFinderView())
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

struct BtnOpenFinderView: View {
    @EnvironmentObject var g: DataProvider

    var body: some View {
        if let project = g.project {
            Button(action: {
                NSWorkspace.shared.open(project.url)
            }, label: {
                Label("在Finder中显示", systemImage: "doc.viewfinder.fill")
            })
        }
    }
}
