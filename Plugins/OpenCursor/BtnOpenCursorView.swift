import SwiftUI

struct BtnOpenCursorView: View {
    @EnvironmentObject var g: DataProvider

    static let shared = BtnOpenCursorView()

    private init() {}

    var body: some View {
        if let project = g.project {
            Button(action: {
                if let vscodeURL = NSWorkspace.shared.urlForApplication(toOpen: URL(fileURLWithPath: "/Applications/Cursor.app")) {
                    NSWorkspace.shared.open([project.url], withApplicationAt: vscodeURL, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
                }
            }, label: {
                Label(
                    title: { Text("用 Cursor 打开") },
                    icon: {
                        Image("Cursor").resizable().scaledToFit().scaleEffect(0.9)
                    }
                )
            })
            .help("用 Cursor 打开")
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 600)
    .frame(height: 600)
}

#Preview("App-Big Screen") {
    RootView {
        ContentLayout()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
