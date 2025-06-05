import SwiftUI
import MagicCore
import OSLog

class OpenTraePlugin: SuperPlugin, SuperLog {
    let emoji = "🤖"
    var label: String = "OpenTrae"
    var icon: String = "brain.head.profile"
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
        AnyView(BtnOpenTraeView())
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

struct BtnOpenTraeView: View {
    @EnvironmentObject var g: DataProvider

    var body: some View {
        if let project = g.project {
            Button(action: {
                if let appURL = NSWorkspace.shared.urlForApplication(toOpen: URL(fileURLWithPath: "/Applications/Trae.app")) {
                    NSWorkspace.shared.open([project.url], withApplicationAt: appURL, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
                }
            }, label: {
                Label(
                    title: { Text("用 Trae 打开") },
                    icon: {
                        Image("Trae").resizable().scaledToFit().scaleEffect(0.9)
                    }
                )
            })
        }
    }
}
