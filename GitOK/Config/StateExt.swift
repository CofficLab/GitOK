import Foundation
import OSLog
import SwiftUI

// MARK: APP状态

extension AppConfig {
    @AppStorage("App.Project")
    static var projectPath: String = ""
    
    static func setProjectPath(_ p: String) {
        AppConfig.projectPath = p
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
