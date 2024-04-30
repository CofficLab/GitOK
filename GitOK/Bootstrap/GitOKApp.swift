import SwiftUI
import SwiftData

@main
struct GitOKApp: App {
    
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
