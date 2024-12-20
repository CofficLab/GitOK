import SwiftUI
import CloudKit

struct DebugCommand: Commands {
    var body: some Commands {
        SidebarCommands()

        #if os(macOS)
        CommandMenu("Debug") {
            Button("Open App Support directory") {
                let dir = AppConfig.getCurrentAppSupportDir()
                
                NSWorkspace.shared.open(dir)
            }
            
            Button("Open container directory") {
                guard let dir = AppConfig.localContainer else {
                    // 显示错误提示
                    let errorAlert = NSAlert()
                    errorAlert.messageText = "Open container directory error"
                    errorAlert.informativeText = "Container directory does not exist"
                    errorAlert.alertStyle = .critical
                    errorAlert.addButton(withTitle: "OK")
                    errorAlert.runModal()
                    
                    return
                }
                
                NSWorkspace.shared.open(dir)
            }
            
            Button("Open documents directory") {
                guard let dir = AppConfig.localDocumentsDir else {
                    // 显示错误提示
                    let errorAlert = NSAlert()
                    errorAlert.messageText = "Open documents directory error"
                    errorAlert.informativeText = "Documents directory does not exist"
                    errorAlert.alertStyle = .critical
                    errorAlert.addButton(withTitle: "OK")
                    errorAlert.runModal()
                    
                    return
                }
                
                NSWorkspace.shared.open(dir)
            }
            
            Button("Open database directory") {
                let dir = AppConfig.getDBFolderURL()
                
                NSWorkspace.shared.open(dir)
            }
            
            Button("Open iCloud Documents") {
                NSWorkspace.shared.open(AppConfig.cloudDocumentsDir)
            }
            
            Button("Open images directory") {
                NSWorkspace.shared.open(AppConfig.imagesDir)
            }
        }
        #endif
    }
}
