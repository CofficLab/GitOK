import Foundation
import MagicKit
import MySQLKit
import NIO
import OSLog
import SQLite3

class DatabaseProvider: ObservableObject, SuperLog, SuperThread {
    var emoji = "💾"

    @Published private(set) var configs: [DatabaseConfig] = []
    @Published private(set) var selectedConfigId: String?
    @Published private(set) var databases: [String] = []
    @Published private(set) var selectedDatabase: String?
    @Published private(set) var selectedTable: String?
    @Published private(set) var records: [[String: Any]] = []
    @Published private(set) var tables: [String] = []
    @Published private(set) var columns: [String] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isTablesLoading = false
    @Published private(set) var isDatabasesLoading = false
    @Published private(set) var error: String?

    private var mysqlConnections: [String: MySQLConnection] = [:]
    private var sqliteConnections: [String: OpaquePointer] = [:]
    private var projectPath: String?
    private let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

    // MARK: - Configuration Management

    func loadConfigs(from project: Project) {
        projectPath = project.path
        let configPath = URL(fileURLWithPath: project.path).appendingPathComponent("database.json").path

        if FileManager.default.fileExists(atPath: configPath),
           let data = try? Data(contentsOf: URL(fileURLWithPath: configPath)),
           let configs = try? JSONDecoder().decode([DatabaseConfig].self, from: data) {
            self.configs = configs
        }
    }

    func saveConfigs() {
        guard let projectPath = projectPath else { return }
        let configPath = URL(fileURLWithPath: projectPath).appendingPathComponent("database.json").path

        if let data = try? JSONEncoder().encode(configs) {
            try? data.write(to: URL(fileURLWithPath: configPath))
        }
    }

    func addConfig(_ config: DatabaseConfig) {
        configs.append(config)
        saveConfigs()
    }

    func removeConfig(id: String) {
        if selectedConfigId == id {
            disconnect(configId: id)
            selectedConfigId = nil
        }
        configs.removeAll { $0.id == id }
        saveConfigs()
    }

    // MARK: - Connection Management

    func connect(configId: String) {
        os_log("Connect to database")

        guard let config = configs.first(where: { $0.id == configId }) else { return }
        selectedConfigId = configId
        selectedTable = nil
        records = []

        switch config.type {
        case .mysql:
            connectMySQL(config: config)
        case .sqlite:
            connectSQLite(config: config)
        }
    }

    private func disconnect(configId: String) {
        if let connection = mysqlConnections.removeValue(forKey: configId) {
            try? connection.close()
        }
        if let db = sqliteConnections.removeValue(forKey: configId) {
            sqlite3_close(db)
        }
        selectedDatabase = nil
        selectedTable = nil
        records = []
        tables = []
        databases = []
        isTablesLoading = true
    }

    // MARK: - MySQL Operations

    private func connectMySQL(config: DatabaseConfig) {
        os_log("Connect to MySQL database")

        guard let host = config.host,
              let port = config.port,
              let username = config.username,
              let password = config.password else {
            error = "Invalid MySQL configuration"
            return
        }

        isLoading = true
        isDatabasesLoading = true
        error = nil

        Task {
            do {
                let eventLoop = eventLoopGroup.next()

                // 创建连接
                let connection = try await MySQLConnection.connect(
                    to: .init(ipAddress: host, port: port),
                    username: username,
                    database: "",
                    password: password,
                    tlsConfiguration: nil,
                    on: eventLoop
                ).get()

                // 获取所有数据库
                let results = try await connection.query("SHOW DATABASES").get()
                var databases: [String] = []
                for row in results {
                    if let dbName = row.column("Database")?.string {
                        // 排除系统数据库
                        if !["information_schema", "mysql", "performance_schema", "sys"].contains(dbName) {
                            databases.append(dbName)
                        }
                    }
                }

                DispatchQueue.main.async {
                    self.mysqlConnections[config.id] = connection
                    self.databases = databases
                    
                    // 如果配置中指定了数据库，自动选择它
                    if let configDB = config.database, databases.contains(configDB) {
                        self.selectDatabase(configDB)
                    }
                    
                    self.isLoading = false
                    self.isDatabasesLoading = false
                }
            } catch {
                os_log(.error, "\(error)")

                DispatchQueue.main.async {
                    self.error = error.localizedDescription
                    self.isLoading = false
                    self.isDatabasesLoading = false
                }
            }
        }
    }

    func selectDatabase(_ database: String) {
        guard let configId = selectedConfigId,
              let connection = mysqlConnections[configId] else {
            return
        }

        isLoading = true
        error = nil
        selectedDatabase = database
        tables = []
        selectedTable = nil
        records = []
        columns = []

        Task {
            do {
                // 切换数据库
                try await connection.query("USE \(database)").get()
                
                // 更新配置
                if let index = self.configs.firstIndex(where: { $0.id == configId }) {
                    DispatchQueue.main.async {
                        self.configs[index].database = database
                        self.saveConfigs()
                    }
                }
                
                // 加载表格列表
                DispatchQueue.main.async {
                    self.loadTables(reason: "Selected database: \(database)")
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    private func loadMySQLTables(connection: MySQLConnection) async throws -> [String] {
        os_log("Load MySQL tables")

        let results = try await connection.query("SHOW TABLES").get()
        var tables: [String] = []

        // First get the database name
        let databaseQuery = try await connection.query("SELECT DATABASE() as db").get()
        let databaseName = databaseQuery.first?.column("db")?.string ?? ""

        // Then get the tables
        for row in results {
            if let tableName = row.column("Tables_in_\(databaseName)")?.string {
                tables.append(tableName)
            }
        }

        self.main.async {
            self.isTablesLoading = false
        }

        return tables
    }

    private func queryMySQLTable(_ tableName: String, connection: MySQLConnection) async throws -> [[String: Any]] {
        os_log("Query MySQL table: \(tableName)")

        let results = try await connection.query("SELECT * FROM \(tableName) LIMIT 100").get()
        var records: [[String: Any]] = []

        // Get column names first
        let columnsResult = try await connection.query("SHOW COLUMNS FROM \(tableName)").get()
        var columnNames: [String] = []
        for row in columnsResult {
            if let columnName = row.column("Field")?.string {
                columnNames.append(columnName)
            }
        }
        
        // Update columns on main thread
        await MainActor.run {
            self.columns = columnNames
        }

        // Now process the data rows
        for row in results {
            var record: [String: Any] = [:]
            for columnName in columnNames {
                if let column = row.column(columnName) {
                    if column.buffer == nil {
                        record[columnName] = NSNull()
                    } else if let stringValue = column.string {
                        record[columnName] = stringValue
                    } else if let intValue = column.int {
                        record[columnName] = intValue
                    } else if let doubleValue = column.double {
                        record[columnName] = doubleValue
                    } else if let boolValue = column.bool {
                        record[columnName] = boolValue
                    } else if let buffer = column.buffer {
                        record[columnName] = Data(buffer.readableBytesView)
                    } else {
                        record[columnName] = "Unsupported type"
                    }
                }
            }
            records.append(record)
        }

        return records
    }

    // MARK: - SQLite Operations

    private func connectSQLite(config: DatabaseConfig) {
        guard let path = config.path else {
            error = "Invalid SQLite configuration"
            return
        }

        var db: OpaquePointer?
        if sqlite3_open(path, &db) == SQLITE_OK, let db = db {
            sqliteConnections[config.id] = db
            loadTables(reason: "Connect to SQLite database")
        } else {
            error = "Failed to open SQLite database"
        }
    }

    private func loadSQLiteTables(db: OpaquePointer) -> [String] {
        isTablesLoading = true

        var tables: [String] = []
        let query = "SELECT name FROM sqlite_master WHERE type='table'"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                if let tableName = sqlite3_column_text(statement, 0) {
                    tables.append(String(cString: tableName))
                }
            }
        }
        sqlite3_finalize(statement)

        isTablesLoading = false

        return tables
    }

    private func querySQLiteTable(_ tableName: String, db: OpaquePointer) -> [[String: Any]] {
        var records: [[String: Any]] = []
        let query = "SELECT * FROM \(tableName) LIMIT 100"
        var statement: OpaquePointer?

        // Get column names first
        var columnNames: [String] = []
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            let columnCount = sqlite3_column_count(statement)
            for i in 0 ..< columnCount {
                if let columnName = sqlite3_column_name(statement, i) {
                    columnNames.append(String(cString: columnName))
                }
            }
        }
        sqlite3_finalize(statement)
        
        // Update columns
        self.columns = columnNames

        // Now get the data
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                var record: [String: Any] = [:]
                let columnCount = sqlite3_column_count(statement)

                for i in 0 ..< columnCount {
                    if let columnName = sqlite3_column_name(statement, i) {
                        let name = String(cString: columnName)
                        let type = sqlite3_column_type(statement, i)

                        switch type {
                        case SQLITE_TEXT:
                            if let text = sqlite3_column_text(statement, i) {
                                record[name] = String(cString: text)
                            }
                        case SQLITE_INTEGER:
                            record[name] = sqlite3_column_int64(statement, i)
                        case SQLITE_FLOAT:
                            record[name] = sqlite3_column_double(statement, i)
                        case SQLITE_NULL:
                            record[name] = NSNull()
                        default:
                            record[name] = "Unsupported type"
                        }
                    }
                }
                records.append(record)
            }
        }
        sqlite3_finalize(statement)
        return records
    }

    // MARK: - Public Interface

    func loadTables(reason: String) {
        os_log("Load tables: \(reason)")

        isTablesLoading = true

        guard let configId = selectedConfigId,
              let config = configs.first(where: { $0.id == configId }) else {
            tables = []
            isTablesLoading = false
            return
        }

        isLoading = true
        error = nil

        switch config.type {
        case .mysql:
            if let connection = mysqlConnections[configId] {
                Task {
                    do {
                        let tables = try await loadMySQLTables(connection: connection)
                        DispatchQueue.main.async {
                            self.tables = tables
                            self.isLoading = false
                        }
                    } catch {
                        DispatchQueue.main.async {
                            self.error = error.localizedDescription
                            self.isLoading = false
                        }
                    }

                    DispatchQueue.main.async {
                        self.isTablesLoading = false
                    }
                }
            }
        case .sqlite:
            if let db = sqliteConnections[configId] {
                tables = loadSQLiteTables(db: db)
                isLoading = false
                isTablesLoading = false
            }
        }
    }

    func queryTable(_ tableName: String) {
        guard let configId = selectedConfigId,
              let config = configs.first(where: { $0.id == configId }) else {
            return
        }

        selectedTable = tableName
        isLoading = true
        error = nil
        records = []
        columns = []

        switch config.type {
        case .mysql:
            if let connection = mysqlConnections[configId] {
                Task {
                    do {
                        let records = try await queryMySQLTable(tableName, connection: connection)
                        DispatchQueue.main.async {
                            self.records = records
                            self.isLoading = false
                        }
                    } catch {
                        DispatchQueue.main.async {
                            self.error = error.localizedDescription
                            self.isLoading = false
                        }
                    }
                }
            }
        case .sqlite:
            if let db = sqliteConnections[configId] {
                records = querySQLiteTable(tableName, db: db)
                isLoading = false
            }
        }
    }

    deinit {
        for (_, connection) in mysqlConnections {
            try? connection.close()
        }
        for (_, db) in sqliteConnections {
            sqlite3_close(db)
        }
        try? eventLoopGroup.syncShutdownGracefully()
    }
}
