import AVKit
import Combine
import Foundation
import MagicCore
import MediaPlayer
import OSLog
import SwiftUI

class AppProvider: NSObject, ObservableObject, AVAudioPlayerDelegate, SuperLog {
    @Published var currentTab: String = "Git"
    @Published var sidebarVisibility: Bool

    var emoji = "🏠"
    private let repoManager: RepoManager

    init(repoManager: RepoManager) {
        self.repoManager = repoManager
        self.sidebarVisibility = repoManager.stateRepo.sidebarVisibility

        super.init()
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
            os_log("\(self.t)🍋 Hide Siedebar")
        }

        self.sidebarVisibility = false
        repoManager.stateRepo.setSidebarVisibility(false)
    }

    func showSidebar(reason: String) {
        let verbose = true
        if verbose {
            os_log("\(self.t)🍋 Show Sidebar(\(reason))")
        }
        self.sidebarVisibility = true
        repoManager.stateRepo.setSidebarVisibility(true)
    }
    
    func setSidebarVisibility(_ v: Bool, reason: String) {
        v ? showSidebar(reason: reason) : hideSidebar()
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
//            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}

