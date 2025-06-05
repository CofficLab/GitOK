import SwiftUI
import MagicCore
import OSLog

class OpenVSCodePlugin: SuperPlugin, SuperLog {
    let emoji = "💻"
    var label: String = "OpenVSCode"
    var icon: String = "desktopcomputer"
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
        AnyView(BtnOpenVSCodeView())
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

struct BtnOpenVSCodeView: View {
    @EnvironmentObject var g: DataProvider

    var body: some View {
        if let project = g.project {
            Button(action: {
                if let vscodeURL = NSWorkspace.shared.urlForApplication(toOpen: URL(fileURLWithPath: "/Applications/Visual Studio Code.app")) {
                    NSWorkspace.shared.open([project.url], withApplicationAt: vscodeURL, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
                }
            }, label: {
                Label(
                    title: { Text("用VSCode打开") },
                    icon: {
                        Image("vscode").resizable().scaledToFit().scaleEffect(0.75)
                    }
                )
            })
        }
    }
}
