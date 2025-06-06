import AVKit
import Combine
import Foundation
import MediaPlayer
import OSLog
import SwiftUI
import MagicCore

class AppProvider: NSObject, ObservableObject, AVAudioPlayerDelegate, SuperLog {
    @Published var currentTab: String = "Git"
    @Published var sidebarVisibility: Bool
    
    var emoji = "🏠"
    private let repoManager: RepoManager
    
    init(repoManager: RepoManager) {
        self.repoManager = repoManager
        self.sidebarVisibility = repoManager.stateRepo.sidebarVisibility
        
        super.init()
        print(self.sidebarVisibility)
    }
    
    func setTab(_ t: String) {
        let verbose = true
        if verbose {
            os_log("\(self.t)Set Tab to \(t)")
        }
        
        self.currentTab = t
        repoManager.stateRepo.setCurrentTab(t)
    }
    
    func hideSidebar() {
        let verbose = true
        if verbose {
            os_log("\(self.t)Hide Siedebar")
        }
        
        self.sidebarVisibility = false
        repoManager.stateRepo.setSidebarVisibility(false)
    }
    
    func showSidebar(reason: String) {
        let verbose = true
        if verbose {
            os_log("\(self.t)Show Sidebar(\(reason))")
        }
    
        print("provider shwo sidebar")
        self.sidebarVisibility = true
        repoManager.stateRepo.setSidebarVisibility(true)
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
