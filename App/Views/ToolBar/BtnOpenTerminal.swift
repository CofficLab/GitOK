import SwiftUI

struct BtnOpenTerminal: View {
    var url: URL

    var body: some View {
        Button(action: {
            guard
                let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Terminal")
            else { return }

            NSWorkspace.shared.open([url], withApplicationAt: appUrl, configuration: NSWorkspace.OpenConfiguration())
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

#Preview {
    AppPreview()
        .frame(width: 800)
}

#Preview("App-Big Screen") {
    RootView {
        ContentLayout()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
