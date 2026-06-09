import Foundation
import OSLog
import SwiftData
import GitOKFoundationKit

/// 应用配置枚举
/// 提供应用的基本配置信息和数据库设置
enum AppConfig: SuperLog {
    /// 日志标识符
    nonisolated static let emoji = "⚙️"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 文件管理器实例
    static let fileManager = FileManager.default
    static func getAppName() -> String {
        if let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String {
            return appName
        } else {
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
        let start = Date()
        let url = AppConfig.getDBFolderURL().appendingPathComponent(dbFileName)
        os_log("\(Self.t)🚀 Startup begin: ModelContainer url=\(url.path)")

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
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            os_log("\(Self.t)✅ Startup end: ModelContainer elapsed=\(String(format: "%.3f", Date().timeIntervalSince(start)))s")
            return container
        } catch {
            os_log(.error, "\(Self.t)❌ ModelContainer failed: \(error.localizedDescription)")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
