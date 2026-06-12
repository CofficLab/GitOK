import SwiftUI
import CloudKit
import GitOKSupportKit

/// 调试命令：在应用菜单中添加调试相关的功能入口
struct DebugCommand: Commands, SuperLog {
    /// 日志标识符
    nonisolated static let emoji = "🐛"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false
    var body: some Commands {
        SidebarCommands()

        #if os(macOS)
        CommandMenu(String(localized: "Debug")) {
            Button(String(localized: "Open App Support Folder")) {
                let dir = AppConfig.getCurrentAppSupportDir()
                
                NSWorkspace.shared.open(dir)
            }
            
            Button(String(localized: "Open Container Folder")) {
                guard let dir = AppConfig.localContainer else {
                    let errorAlert = NSAlert()
                    errorAlert.messageText = String(localized: "Error Opening Container Folder")
                    errorAlert.informativeText = String(localized: "Container folder does not exist")
                    errorAlert.alertStyle = .critical
                    errorAlert.addButton(withTitle: String(localized: "OK"))
                    errorAlert.runModal()
                    
                    return
                }
                
                NSWorkspace.shared.open(dir)
            }
            
            Button(String(localized: "Open Documents Folder")) {
                guard let dir = AppConfig.localDocumentsDir else {
                    let errorAlert = NSAlert()
                    errorAlert.messageText = String(localized: "Error Opening Documents Folder")
                    errorAlert.informativeText = String(localized: "Documents folder does not exist")
                    errorAlert.alertStyle = .critical
                    errorAlert.addButton(withTitle: String(localized: "OK"))
                    errorAlert.runModal()
                    
                    return
                }
                
                NSWorkspace.shared.open(dir)
            }
            
            Button(String(localized: "Open Database Folder")) {
                let dir = AppConfig.getDBFolderURL()
                
                NSWorkspace.shared.open(dir)
            }
        }
        #endif
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .hideTabPicker()
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}
