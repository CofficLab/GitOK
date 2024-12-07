import AVKit
import Combine
import Foundation
import MediaPlayer
import OSLog
import SwiftUI
import MagicKit

class AppProvider: NSObject, ObservableObject, AVAudioPlayerDelegate, SuperLog {
    @Published var currentTab: String = "Git"
    @Published var sidebarVisibility = AppConfig.sidebarVisibility

    var emoji = "🏠"
    
    func setTab(_ t: String) {        
        self.currentTab = t
        AppConfig.setcurrentTab(t)
    }
    
    func hideSidebar() {
        let verbose = true
        if verbose {
            os_log("\(self.t)Hide Siedebar")
        }
        
        self.sidebarVisibility = false
        AppConfig.setSidebarVisibility(false)
    }
    
    func showSidebar() {
        let verbose = false
        if verbose {
            os_log("\(self.t)Show Sidebar")
        }
    
        self.sidebarVisibility = true
        AppConfig.setSidebarVisibility(true)
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
