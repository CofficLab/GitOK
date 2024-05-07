import SwiftData
import SwiftUI

@main
struct GitOKApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: MacAgent

    var body: some Scene {
        WindowGroup {
            RootView {
                Content()
            }
        }
        .modelContainer(AppConfig.getContainer())
        .commands(content: {
            DebugCommand()
        })
    }
}

#Preview {
    AppPreview()
}
