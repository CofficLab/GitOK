import Foundation
import OSLog
import SwiftData
import SwiftUI

enum AppConfig {
    static let fileManager = FileManager.default
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

// MARK: 数据库配置

extension AppConfig {
    static var dbFileName = AppConfig.debug ? "gitok_debug.db" : "gitok.db"
    
    static func getContainer() -> ModelContainer {
        let url = AppConfig.getDBFolderURL().appendingPathComponent(dbFileName)

        let schema = Schema([
            Project.self,
            GitUserConfig.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: url,
            allowsSave: true,
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
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
