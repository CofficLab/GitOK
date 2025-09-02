import Foundation
import OSLog
import SwiftData
import SwiftUI

enum AppConfig {
    static let fileManager = FileManager.default
    static let logger = Logger.self
    static func getAppName() -> String {
        if let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String {
            return appName
        } else {
            os_log("无法获取应用程序名称")

            return ""
        }
    }

    static var debug: Bool {
        #if DEBUG
            true
        #else
            false
        #endif
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .hideTabPicker()
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}
