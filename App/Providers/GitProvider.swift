import AVKit
import Combine
import Foundation
import MediaPlayer
import OSLog
import SwiftUI

class GitProvider: NSObject, ObservableObject, SuperLog {
    @Published var branches: [String] = []
    @Published var project: Project?
    @Published var commit: GitCommit?
    @Published var file: File?
    
    var git = Git()
    var emoji = "🏠"

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
        
        try git.setBranch(branch, project.path, verbose: true)
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
