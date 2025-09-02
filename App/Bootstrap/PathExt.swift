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
    static let containerDir = fileManager.url(forUbiquityContainerIdentifier: containerIdentifier)
    static var cloudDocumentsDir: URL {
        if let c = containerDir {
            return c.appending(component: "Documents")
        }

        if let documentsDirectory = localDocumentsDir {
            return documentsDirectory
        }

        fatalError()
    }
    
    // MARK: 数据库
    
    static func getDBFolderURL() -> URL {
        return AppConfig.getCurrentAppSupportDir()
    }

    static var coverDir: URL {
        if let localDocumentsDir = AppConfig.localDocumentsDir {
            return localDocumentsDir.appendingPathComponent(coversDirName)
        }

        fatalError()
    }

    static var imagesDir: URL {
        let url = AppConfig.cloudDocumentsDir.appendingPathComponent(AppConfig.imagesDirName)

        if !fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
                os_log("🍋 DB::创建 Images 目录成功")
            } catch {
                os_log("创建 Images 目录失败 \(error.localizedDescription)")
            }
        }

        return url
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
