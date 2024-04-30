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

    @AppStorage("App.CurrentTaskUUID")
    static var currentTaskUUID: String = ""

    static func setcurrentTaskUUID(_ id: String) {
        AppConfig.currentTaskUUID = id
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
