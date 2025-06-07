import SwiftUI

struct BtnOpenXcode: View {
    var url: URL

    var body: some View {
        Button(action: {
            if let vscodeURL = NSWorkspace.shared.urlForApplication(toOpen: URL(fileURLWithPath: "/Applications/Xcode.app")) {
                NSWorkspace.shared.open([url], withApplicationAt: vscodeURL, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
            }
        }, label: {
            Label(
                title: { Text("用Xcode打开") },
                icon: {
                    Image("Xcode").resizable().scaledToFit().scaleEffect(0.85)
                }
            )
        })
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
//            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
