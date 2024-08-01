import SwiftData
import SwiftUI
import Sparkle

@main
struct GitOKApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: MacAgent
    
    private let updaterController: SPUStandardUpdaterController

        init() {
            updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        }

    var body: some Scene {
        WindowGroup {
            RootView {
                Content()
            }
        }
        .modelContainer(AppConfig.getContainer())
        .commands(content: {
            DebugCommand() 
            
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
        })
        
    }
}

#Preview {
    AppPreview()
}
