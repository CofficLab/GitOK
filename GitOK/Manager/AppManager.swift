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
    @Published var project: Project? = AppConfig.getProject()
    
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
        self.project = p
        AppConfig.setProject(p?.path ?? "")
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
