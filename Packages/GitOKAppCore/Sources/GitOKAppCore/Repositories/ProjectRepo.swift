import Foundation
import SwiftData
import OSLog

public class ProjectRepo: BaseRepositoryImpl<Project>, ProjectRepoProtocol {
    
    // MARK: - 基础CRUD操作
    
    public func create(url: URL) throws -> Project {
        let project = Project(url)
        
        // 设置新项目的order为-1，使其显示在列表最前面
        project.order = -1
        
        modelContext.insert(project)
        try save()
        return project
    }
    
    public func findById(_ id: URL) throws -> Project? {
        let descriptor = FetchDescriptor<Project>(
            predicate: #Predicate<Project> { project in
                project.url == id
            }
        )
        return try fetch(descriptor).first
    }
    
    public func findByPath(_ path: String) throws -> Project? {
        let url = URL(fileURLWithPath: path)
        let descriptor = FetchDescriptor<Project>(
            predicate: #Predicate<Project> { project in
                project.url == url
            }
        )
        return try fetch(descriptor).first
    }
    
    public func update(_ project: Project) throws {
        try save()
        logger.info("📝 Updated project: \(project.title)")
    }
    
    // MARK: - 查询操作
    
    public func findAll(sortedBy order: SortOrder = .ascending) throws -> [Project] {
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
    
    public func exists(path: String) -> Bool {
        do {
            return try findByPath(path) != nil
        } catch {
            logger.error("❌ Error checking project existence: \(error.localizedDescription)")
            return false
        }
    }
    
    public func updateOrder(_ project: Project, newOrder: Int16) throws {
        project.order = newOrder
        try update(project)
        logger.info("📊 Updated project order: \(project.title) -> \(newOrder)")
    }
    
    public func getProjectCount() throws -> Int {
        return try fetchAll().count
    }
    
    // MARK: - 高级查询
    
    public func findProjectsCreatedAfter(_ date: Date) throws -> [Project] {
        let descriptor = FetchDescriptor<Project>(
            predicate: #Predicate<Project> { project in
                project.timestamp > date
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try fetch(descriptor)
    }
    
    public func findProjectsByTitle(containing searchText: String) throws -> [Project] {
        let descriptor = FetchDescriptor<Project>(
            predicate: #Predicate<Project> { project in
                project.url.lastPathComponent.localizedStandardContains(searchText)
            }
        )
        return try fetch(descriptor)
    }
}
