import SwiftUI

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