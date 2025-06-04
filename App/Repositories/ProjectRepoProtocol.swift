import Foundation
import SwiftData

// MARK: - Project Repository协议

protocol ProjectRepoProtocol: BaseRepo where Entity == Project {
    // 基础CRUD操作
    func create(url: URL) throws -> Project
    func findById(_ id: URL) throws -> Project?
    func findByPath(_ path: String) throws -> Project?
    func update(_ project: Project) throws
    
    // 查询操作
    func findAll(sortedBy order: SortOrder) throws -> [Project]
    func findGitProjects() throws -> [Project]
    func findNonGitProjects() throws -> [Project]
    func findCleanProjects() throws -> [Project]
    func findProjectsWithChanges() throws -> [Project]
    
    // 业务操作
    func exists(path: String) -> Bool
    func updateOrder(_ project: Project, newOrder: Int16) throws
    func getProjectCount() throws -> Int
}

enum SortOrder {
    case ascending
    case descending
}
