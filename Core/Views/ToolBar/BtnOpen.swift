import SwiftUI

struct BtnOpen: View {
    var url: URL

    var body: some View {
        Button(action: {
            if let vscodeURL = NSWorkspace.shared.urlForApplication(toOpen: URL(fileURLWithPath: "/Applications/Visual Studio Code.app")) {
                NSWorkspace.shared.open([url], withApplicationAt: vscodeURL, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
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

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .hideTabPicker()
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}
