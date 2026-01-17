import SwiftUI

struct BtnOpenTrae: View {
    var url: URL

    var body: some View {
        Button(action: {
            if let appURL = NSWorkspace.shared.urlForApplication(toOpen: URL(fileURLWithPath: "/Applications/Trae.app")) {
                NSWorkspace.shared.open([url], withApplicationAt: appURL, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
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
