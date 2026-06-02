import Combine
import Foundation
import GitOKSupportKit
import SwiftData
import OSLog

// MARK: - Repository管理器

class RepoManager: ObservableObject, SuperLog {
    static let emoji = "🏗️"
    private let modelContext: ModelContext
    private let verbose = false
    
    // Repository实例
    lazy var projectRepo: any ProjectRepoProtocol = {
        ProjectRepo(modelContext: modelContext)
    }()
    
    lazy var stateRepo: any StateRepoProtocol = {
        StateRepo()
    }()
    
    lazy var gitUserConfigRepo: any GitUserConfigRepoProtocol = {
        GitUserConfigRepo(modelContext: modelContext)
    }()
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        if verbose {
            os_log("\(Self.onInit)")
        }
    }
    
    // 便利方法
    func saveContext() throws {
        try modelContext.save()
        os_log("\(self.t)Context saved")
    }
    
    func rollback() {
        modelContext.rollback()
        os_log("\(self.t)Context rolled back")
    }
}

// MARK: - Repository管理器扩展

extension RepoManager {
    static func create(with container: ModelContainer) -> RepoManager {
        let context = ModelContext(container)
        return RepoManager(modelContext: context)
    }
}
