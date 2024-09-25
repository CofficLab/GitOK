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
        .windowToolbarStyle(.unified(showsTitle: false))
        .modelContainer(AppConfig.getContainer())
        .commands(content: {
            DebugCommand() 
            
            CommandGroup(after: .appInfo) {
                UpdaterView(updater: updaterController.updater)
            }
        })
        
    }
}

#Preview {
    AppPreview()
}
