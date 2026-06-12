import Combine
import Foundation
import GitOKSupportKit
import SwiftData
import OSLog

// MARK: - Repository管理器

public class RepoManager: ObservableObject, SuperLog {
    public static let emoji = "🏗️"
    public nonisolated static let verbose = false
    private let modelContext: ModelContext
    
    // Repository实例
    public lazy var projectRepo: any ProjectRepoProtocol = {
        ProjectRepo(modelContext: modelContext)
    }()
    
    public lazy var stateRepo: any StateRepoProtocol = {
        StateRepo()
    }()
    
    public lazy var gitUserConfigRepo: any GitUserConfigRepoProtocol = {
        GitUserConfigRepo(modelContext: modelContext)
    }()
    
public init(modelContext: ModelContext) {
        self.modelContext = modelContext
        if Self.verbose {
            os_log("\(Self.onInit)")
        }
    }
    
    // 便利方法
    public func saveContext() throws {
        try modelContext.save()
        if Self.verbose {
            os_log("\(self.t)Context saved")
        }
    }
    
    public func rollback() {
        modelContext.rollback()
        if Self.verbose {
            os_log("\(self.t)Context rolled back")
        }
    }
}

// MARK: - Repository管理器扩展

extension RepoManager {
    static func create(with container: ModelContainer) -> RepoManager {
        let context = ModelContext(container)
        return RepoManager(modelContext: context)
    }
}
