import AVKit
import Combine
import Foundation
import MediaPlayer
import OSLog
import SwiftUI
import MagicKit

class GitProvider: NSObject, ObservableObject, SuperLog {
    @Published var branches: [String] = []
    @Published var project: Project?
    @Published var commit: GitCommit?
    @Published var file: File?
    
    var emoji = "🏠"
    
    var currentBranch: Branch? {
        guard let project = project else {
            return nil
        }
        
        do {
            return try GitShell.getCurrentBranch(project.path)
        } catch _ {
            return nil
        }
    }

    func setFile(_ f: File?) {
        file = f
    }

    func setCommit(_ c: GitCommit?) {
        commit = c
    }
    
    func setProject(_ p: Project?, reason: String) {
        let verbose = false

        if verbose {
            os_log("\(self.t)Set Project(\(reason))")
            os_log("  ➡️ \(p?.path ?? "")")
        }
        
        self.project = p
        AppConfig.setProjectPath(p?.path ?? "")
    }
    
    func setBranch(_ branch: Branch?) throws {
        let verbose = false

        if verbose {
            os_log("\(self.t)Set Branch to \(branch?.name ?? "-")")
        }
        
        guard let project = project, let branch = branch else {
            return
        }
        
        if branch.name == currentBranch?.name {
            return
        }
        
        try GitShell.setBranch(branch, project.path, verbose: true)
    }

    func commit(_ message: String) {
        guard let project = self.project else { return }
        
        do {
            try GitShell.commit(project.path, commit: message)
        } catch {
            // 错误处理...
        }
    }
    
    func pull() {
        guard let project = self.project else { return }
        
        do {
            try GitShell.pull(project.path)
        } catch {
            // 错误处理...
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
