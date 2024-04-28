import SwiftUI
import SwiftData

@main
struct GitOKApp: App {
    
    var body: some Scene {
        WindowGroup {
            Content()
                .environmentObject(AppManager())
                .environmentObject(WebConfig())
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
