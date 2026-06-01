import Foundation
import SwiftData
import OSLog
import MagicKit

// MARK: - Repository基础协议

protocol BaseRepo {
    associatedtype Entity: PersistentModel
    
    var modelContext: ModelContext { get }
    var logger: Logger { get }
    
    func save() throws
    func fetch(_ descriptor: FetchDescriptor<Entity>) throws -> [Entity]
    func fetchAll() throws -> [Entity]
    func delete(_ entity: Entity) throws
    func deleteAll() throws
}

// MARK: - Repository基础实现

class BaseRepositoryImpl<T: PersistentModel>: BaseRepo, SuperLog {
    nonisolated static var emoji: String { "🏠" }
    typealias Entity = T
    
    let modelContext: ModelContext
    let logger = Logger(subsystem: "com.yueyi.gitok", category: "Repository")
    private var verbose = false
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func save() throws {
        try modelContext.save()
    }
    
    func fetch(_ descriptor: FetchDescriptor<T>) throws -> [T] {
        let results = try modelContext.fetch(descriptor)
        if verbose {
            logger.debug("\(self.t)📖 Fetched \(results.count) \(String(describing: T.self))")
        }
        return results
    }
    
    func fetchAll() throws -> [T] {
        let descriptor = FetchDescriptor<T>()
        return try fetch(descriptor)
    }
    
    func delete(_ entity: T) throws {
        modelContext.delete(entity)
        try save()
        logger.info("🗑️ Deleted \(String(describing: T.self))")
    }
    
    func deleteAll() throws {
        let entities = try fetchAll()
        for entity in entities {
            modelContext.delete(entity)
        }
        try save()
        logger.info("🗑️ Deleted all \(entities.count) \(String(describing: T.self))")
    }
}
