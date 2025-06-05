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

    func addListView() -> AnyView {
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

struct BtnOpenRemoteView: View {
    @EnvironmentObject var g: DataProvider
    @State var remote: String = ""

    var body: some View {
        if let project = g.project {
            Button(action: {
                remote = GitShell.getRemote(project.path).trimmingCharacters(in: .whitespacesAndNewlines)

                if remote.hasPrefix("git@") {
                    remote = remote.replacingOccurrences(of: ":", with: "/")
                    remote = remote.replacingOccurrences(of: "git@", with: "https://")
                }

                if let url = URL(string: remote) {
                    NSWorkspace.shared.open(url)
                }
            }, label: {
                Label(
                    title: { Text("打开远程仓库") },
                    icon: { Image(systemName: "safari") }
                )
            })
        }
    }
}