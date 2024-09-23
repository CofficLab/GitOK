import AVKit
import Combine
import Foundation
import MediaPlayer
import OSLog
import SwiftUI

class AppProvider: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var branches: [String] = []
    @Published var project: Project?
    @Published var commit: GitCommit?
    @Published var file: File?
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

    func setCommit(_ c: GitCommit?) {
        commit = c
    }
    
    var currentBranch: Branch? {
        guard let project = project else {
            return nil
        }
        
        do {
            return try git.getCurrentBranch(project.path)
        } catch _ {
            return nil
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
    
    func setProject(_ p: Project?) {
        let verbose = true

        if verbose {
            os_log("\(self.label)Set Project to \(p?.path ?? "")")
        }
        self.project = p
        AppConfig.setProjectPath(p?.path ?? "")
    }
    
    func setTab(_ t: ActionTab) {
        os_log("\(self.label)Set Tab to \(t.rawValue)")
        self.currentTab = t
        AppConfig.setcurrentTab(t)
    }
    
    func setBranch(_ branch: Branch?) throws {
        os_log("\(self.label)Set Branch to \(branch?.name ?? "-")")
        
        guard let project = project, let branch = branch else {
            return
        }
        
        if branch.name == currentBranch?.name {
            os_log("\(self.label)Alrady on branch \(branch.name)")
            return
        }
        
        _ = try git.setBranch(branch, project.path, verbose: true)
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
