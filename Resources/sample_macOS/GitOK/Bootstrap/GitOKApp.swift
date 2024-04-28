import SwiftUI
import SwiftData

@main
struct GitOKApp: App {
    var body: some Scene {
        WindowGroup {
            Content()
                .environmentObject(AppManager())
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
