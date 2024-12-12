import AVKit
import Combine
import Foundation
import MediaPlayer
import OSLog
import SwiftUI
import MagicKit

class ProjectProvider: NSObject, ObservableObject, SuperLog {
    @Published var project: Project?
    
    var emoji = "🏠"
    
    func setProject(_ p: Project?, reason: String) {
        let verbose = false

        if verbose {
            os_log("\(self.t)Set Project(\(reason))")
            os_log("  ➡️ \(p?.path ?? "")")
        }
        
        self.project = p
        AppConfig.setProjectPath(p?.path ?? "")
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
