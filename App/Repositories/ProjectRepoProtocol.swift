import Foundation
import SwiftData
import SwiftUI

protocol ProjectRepoProtocol: BaseRepo where Entity == Project {
    // 基础CRUD操作
    func create(url: URL) throws -> Project
    func findById(_ id: URL) throws -> Project?
    func findByPath(_ path: String) throws -> Project?
    func update(_ project: Project) throws
    
    // 查询操作
    func findAll(sortedBy order: SortOrder) throws -> [Project]
    
    // 业务操作
    func exists(path: String) -> Bool
    func updateOrder(_ project: Project, newOrder: Int16) throws
    func getProjectCount() throws -> Int
}

enum SortOrder {
    case ascending
    case descending
}

#Preview("App-Big Screen") {
    RootView {
        ContentLayout()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
