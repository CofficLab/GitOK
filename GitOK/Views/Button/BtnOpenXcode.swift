import SwiftUI

struct BtnOpenXcode: View {
    var url: URL

    var body: some View {
        Button(action: {
            if let vscodeURL = NSWorkspace.shared.urlForApplication(toOpen: URL(fileURLWithPath: "/Applications/Xcode.app")) {
                NSWorkspace.shared.open([url], withApplicationAt: vscodeURL, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
            }
        }, label: {
            Label("用Xcode打开", systemImage: "square.and.pencil.circle")
        })
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
