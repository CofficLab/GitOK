import Foundation

struct DatabaseConfig: Codable, Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var type: DatabaseType
    
    // MySQL specific
    var host: String?
    var port: Int?
    var username: String?
    var password: String?
    var database: String?
    
    // SQLite specific
    var path: String?
    
    enum DatabaseType: String, Codable {
        case mysql
        case sqlite
    }
    
    static func createMySQLConfig(name: String, host: String, port: Int, username: String, password: String, database: String) -> DatabaseConfig {
        DatabaseConfig(
            name: name,
            type: .mysql,
            host: host,
            port: port,
            username: username,
            password: password,
            database: database
        )
    }
    
    static func createSQLiteConfig(name: String, path: String) -> DatabaseConfig {
        DatabaseConfig(
            name: name,
            type: .sqlite,
            path: path
        )
    }
} 
