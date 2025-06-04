import Foundation
import SwiftData
import SwiftUI

// MARK: 数据库配置

extension AppConfig {
    static var dbFileName = AppConfig.debug ? "gitok_debug.db" : "gitok.db"
    
    static func getContainer() -> ModelContainer {
        let url = AppConfig.getDBFolderURL().appendingPathComponent(dbFileName)

        let schema = Schema([
            Project.self
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
    
    // 新增：创建Repository管理器
    static func createRepositoryManager() -> RepoManager {
        let container = getContainer()
        return RepoManager.create(with: container)
    }
}

#Preview {
    AppPreview()
}
