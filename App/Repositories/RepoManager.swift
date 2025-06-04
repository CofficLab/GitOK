import Foundation
import SwiftData
import OSLog

// MARK: - Repository管理器

class RepoManager: ObservableObject {
    private let modelContext: ModelContext
    private let logger = Logger(subsystem: "com.yueyi.gitok", category: "RepositoryManager")
    
    // Repository实例
    lazy var projectRepo: any ProjectRepoProtocol = {
        ProjectRepo(modelContext: modelContext)
    }()
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        logger.info("🏗️ RepositoryManager initialized")
    }
    
    // 便利方法
    func saveContext() throws {
        try modelContext.save()
        logger.info("💾 Context saved")
    }
    
    func rollback() {
        modelContext.rollback()
        logger.warning("↩️ Context rolled back")
    }
}

// MARK: - Repository管理器扩展

extension RepoManager {
    static func create(with container: ModelContainer) -> RepoManager {
        let context = ModelContext(container)
        return RepoManager(modelContext: context)
    }
}
