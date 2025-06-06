import SwiftUI

struct BtnOpenCursorView: View {
    @EnvironmentObject var g: DataProvider

    var body: some View {
        if let project = g.project {
            Button(action: {
                guard
                    let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.cursor.Cursor")
                else { return }

                NSWorkspace.shared.open([project.url], withApplicationAt: appUrl, configuration: NSWorkspace.OpenConfiguration())
            }, label: {
                Label(
                    title: { Text("用Cursor打开") },
                    icon: {
                        Image("Cursor")
                            .resizable()
                            .frame(width: 24, height: 24)
                    }
                )
            })
        }
    }
}
