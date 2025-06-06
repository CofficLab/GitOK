import SwiftUI

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