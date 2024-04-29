import AVKit
import Combine
import Foundation
import MediaPlayer
import OSLog
import SwiftUI

class AppManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var branches: [String] = []
    @Published var commit: GitCommit?
    @Published var commitId: String?
    @Published var project: Project?
    @Published var file: File?
    
    var currentBranch: Branch? {
        guard let project = project else {
            return nil
        }
        
        return try! Git.getCurrentBranch(project.path)
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
        os_log("\(self.label)Set Project to \(p?.path ?? "")")
        self.project = p
        AppConfig.setProjectPath(p?.path ?? "")
    }
    
    func setBranch(_ branch: Branch?) throws {
        os_log("\(self.label)Set Branch to \(branch?.name ?? "-")")
        
        guard let project = project, let branch = branch else {
            return
        }
        
        if branch.name == currentBranch?.name {
            return
        }
        
        _ = try Git.setBranch(branch, project.path, verbose: false)
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
