import Foundation
import OSLog
import SwiftUI

// MARK: 路径配置

extension AppConfig {
    // MARK: Application Support
    
    static func getAppSupportDir() -> URL {
        try! fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }
    
    static func getCurrentAppSupportDir() -> URL {
        getAppSupportDir().appendingPathComponent(getAppName())
    }
    
    
    static let localContainer = localDocumentsDir?.deletingLastPathComponent()
    static let localDocumentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
    
    // MARK: 数据库
    
    static func getDBFolderURL() -> URL {
        return AppConfig.getCurrentAppSupportDir()
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .setInitialTab(IconPlugin.label)
        .hideSidebar()
        .hideProjectActions()
        .setInitialTab(IconPlugin.label)
        .inRootView()
        .frame(width: 800)
        .frame(height: 800)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideProjectActions()
        .setInitialTab(IconPlugin.label)
        .hideSidebar()
        .setInitialTab(IconPlugin.label)
        .inRootView()
        .frame(width: 800)
        .frame(height: 1200)
}
