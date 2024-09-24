import AVKit
import Combine
import Foundation
import MediaPlayer
import OSLog
import SwiftUI

class AppProvider: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var message: String = ""
    @Published var currentTab: ActionTab = (ActionTab(rawValue: AppConfig.currentTab) ?? .Git)
    @Published var sidebarVisibility = AppConfig.sidebarVisibility
    
    var git = Git()
    
    func setMessage(_ m: String) {
        message = m
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.message = ""
        }
    }
    
    var label = "🏠 AppManager::"
    
    func alert(_ message: String, info: String) {
        // 显示错误提示
        let errorAlert = NSAlert()
        errorAlert.messageText = message
        errorAlert.informativeText = info
        errorAlert.alertStyle = .critical
        errorAlert.addButton(withTitle: "好的")
        errorAlert.runModal()
    }
    
    func setTab(_ t: ActionTab) {
        os_log("\(self.label)Set Tab to \(t.rawValue)")
        self.currentTab = t
        AppConfig.setcurrentTab(t)
    }
    
    func hideSidebar() {
        os_log("\(self.label)Hide Siedebar")
        self.sidebarVisibility = false
        AppConfig.setSidebarVisibility(false)
        print(AppConfig.sidebarVisibility)
    }
    
    func showSidebar() {
        os_log("\(self.label)Show Sidebar")
        self.sidebarVisibility = true
        AppConfig.setSidebarVisibility(true)
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
