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
    
    @AppStorage("App.CurrentTab")
    static var currentTab: String = ""

    static func setcurrentTab(_ tab: ActionTab) {
        AppConfig.currentTab = tab.rawValue
    }
    
    @AppStorage("App.SidebarVisibility")
    static var sidebarVisibility: Bool = true

    static func setSidebarVisibility(_ v: Bool) {
        AppConfig.sidebarVisibility = v
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
