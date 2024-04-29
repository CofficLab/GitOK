import AVKit
import Combine
import Foundation
import MediaPlayer
import OSLog
import SwiftUI

class AppManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var branch: String = ""
    @Published var branches: [String] = []
    @Published var commit: GitCommit?
    @Published var commitId: String?
    @Published var project: Project?
    @Published var file: File?
    
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
        AppConfig.setProject(p)
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
