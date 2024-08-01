import SwiftUI

struct BtnOpen: View {
    var url: URL

    var body: some View {
        Button(action: {
            if let vscodeURL = NSWorkspace.shared.urlForApplication(toOpen: URL(fileURLWithPath: "/Applications/Visual Studio Code.app")) {
                NSWorkspace.shared.open([url], withApplicationAt: vscodeURL, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
            }
        }, label: {
            Label("用VSCode打开", systemImage: "pencil.circle")
        })
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
