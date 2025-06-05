import SwiftUI
import MagicCore
import OSLog

class OpenTerminalPlugin: SuperPlugin, SuperLog {
    let emoji = "⌨️"
    var label: String = "OpenTerminal"
    var icon: String = "apple.terminal"
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
        AnyView(BtnOpenTerminalView())
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

struct BtnOpenTerminalView: View {
    @EnvironmentObject var g: DataProvider

    var body: some View {
        if let project = g.project {
            Button(action: {
                guard
                    let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Terminal")
                else { return }

                NSWorkspace.shared.open([project.url], withApplicationAt: appUrl, configuration: NSWorkspace.OpenConfiguration())
            }, label: {
                Label(
                    title: { Text("用终端打开") },
                    icon: {
                        Image(systemName: "apple.terminal")
                    }
                )
            })
        }
    }
}
