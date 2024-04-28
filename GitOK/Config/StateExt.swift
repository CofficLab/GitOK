import Foundation
import OSLog
import SwiftUI

// MARK: APP状态

extension AppConfig {
    @AppStorage("App.Project")
    static var projectPath: String = ""
    
    static func setProject(_ project: Project?) {
        AppConfig.projectPath = project?.path ?? ""
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
