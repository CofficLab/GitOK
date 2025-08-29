import Foundation
import SwiftData
import OSLog
import SwiftUI

class ProjectRepo: BaseRepositoryImpl<Project>, ProjectRepoProtocol {
    
    // MARK: - 基础CRUD操作
    
    func create(url: URL) throws -> Project {
        let project = Project(url)
        
        // 设置新项目的order为-1，使其显示在列表最前面
        project.order = -1
        
        modelContext.insert(project)
        try save()
        logger.info("➕ Created project: \(project.title)")
        return project
    }
    
    func findById(_ id: URL) throws -> Project? {
        let descriptor = FetchDescriptor<Project>(
            predicate: #Predicate<Project> { project in
                project.url == id
            }
        )
        return try fetch(descriptor).first
    }
    
    func findByPath(_ path: String) throws -> Project? {
        let url = URL(fileURLWithPath: path)
        let descriptor = FetchDescriptor<Project>(
            predicate: #Predicate<Project> { project in
                project.url == url
            }
        )
        return try fetch(descriptor).first
    }
    
    func update(_ project: Project) throws {
        try save()
        logger.info("📝 Updated project: \(project.title)")
    }
    
    // MARK: - 查询操作
    
    func findAll(sortedBy order: SortOrder = .ascending) throws -> [Project] {
        let sortDescriptor = SortDescriptor<Project>(
            \.order,
            order: order == .ascending ? .forward : .reverse
        )
        let descriptor = FetchDescriptor<Project>(
            sortBy: [sortDescriptor]
        )
        return try fetch(descriptor)
    }
    
    // MARK: - 业务操作
    
    func exists(path: String) -> Bool {
        do {
            return try findByPath(path) != nil
        } catch {
            logger.error("❌ Error checking project existence: \(error.localizedDescription)")
            return false
        }
    }
    
    func updateOrder(_ project: Project, newOrder: Int16) throws {
        project.order = newOrder
        try update(project)
        logger.info("📊 Updated project order: \(project.title) -> \(newOrder)")
    }
    
    func getProjectCount() throws -> Int {
        return try fetchAll().count
    }
    
    // MARK: - 高级查询
    
    func findProjectsCreatedAfter(_ date: Date) throws -> [Project] {
        let descriptor = FetchDescriptor<Project>(
            predicate: #Predicate<Project> { project in
                project.timestamp > date
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try fetch(descriptor)
    }
    
    func findProjectsByTitle(containing searchText: String) throws -> [Project] {
        let descriptor = FetchDescriptor<Project>(
            predicate: #Predicate<Project> { project in
                project.url.lastPathComponent.localizedStandardContains(searchText)
            }
        )
        return try fetch(descriptor)
    }
}

#Preview("App-Big Screen") {
    RootView {
        ContentLayout()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
