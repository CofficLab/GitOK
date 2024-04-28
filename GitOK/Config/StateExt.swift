import Foundation
import OSLog
import SwiftUI

// MARK: APP状态

extension AppConfig {
    @AppStorage("App.Project")
    static var projectPath: String = ""
    
    static func setProject(_ path: String) {
        AppConfig.projectPath = path
    }
    
    static func getProject() -> Project? {
        nil
//        if let url = URL(string: AppConfig.projectPath) {
//            Project(url)
//        } else {
//            nil
//        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
