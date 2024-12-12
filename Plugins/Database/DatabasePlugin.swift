import SwiftUI
import Foundation
import OSLog
import MagicKit

class DatabasePlugin: SuperPlugin, SuperLog {
    // MARK: - SuperPlugin Protocol
    var emoji = "💾"
    var label: String = "DB"
    var icon: String = "database.fill"
    var isTab: Bool = true
    
    // MARK: - State
    @Published var provider: DatabaseProvider?
    
    init() {
        self.provider = DatabaseProvider()
    }
    
    // MARK: - View Builders
    func addDBView() -> AnyView {
        AnyView(EmptyView())
    }
    
    func addListView() -> AnyView {
        guard let provider = provider else {
            return AnyView(EmptyView())
        }

        return AnyView(TableList().environmentObject(provider))
    }
    
    func addDetailView() -> AnyView {
        guard let provider = provider else {
            return AnyView(EmptyView())
        }

        return AnyView(DatabaseDetail().environmentObject(provider))
    }
    
    func addToolBarTrailingView() -> AnyView {
        AnyView(EmptyView())
    }
    
    // MARK: - Lifecycle Methods
    func onInit() {
        os_log("\(self.t) onInit")
    }
    
    func onAppear(project: Project?) {
        os_log("\(self.t) onAppear")
        if let project = project {
            detectDatabase(in: project)
        }
    }
    
    func onDisappear() {
        os_log("\(self.t) onDisappear")
    }
    
    func onPlay() {
        os_log("\(self.t) onPlay")
    }
    
    func onPlayStateUpdate() {
        os_log("\(self.t) onPlayStateUpdate")
    }
    
    func onPlayAssetUpdate() {
        os_log("\(self.t) onPlayAssetUpdate")
    }
    
    // MARK: - Database Detection
    private func detectDatabase(in project: Project) {
        // 检查是否存在数据库配置文件
        let configPath = URL(fileURLWithPath: project.path).appendingPathComponent("database.yml").path
        let sqlitePath = URL(fileURLWithPath: project.path).appendingPathComponent("database.sqlite").path
        
        if FileManager.default.fileExists(atPath: configPath) {
            // 读取MySQL配置
            if let config = loadMySQLConfig(from: configPath) {
                provider?.connect(type: .mysql, path: project.path, config: config)
            }
        } else if FileManager.default.fileExists(atPath: sqlitePath) {
            // 连接SQLite数据库
            provider?.connect(type: .sqlite, path: sqlitePath)
        }
        
        // 加载数据表
        provider?.loadTables()
    }
    
    private func loadMySQLConfig(from path: String) -> DatabaseConfig? {
        // 读取YAML配置文件
        guard let contents = try? String(contentsOfFile: path, encoding: .utf8) else {
            return nil
        }
        
        // 解析YAML内容
        let lines = contents.components(separatedBy: .newlines)
        var config: [String: String] = [:]
        
        for line in lines {
            let parts = line.split(separator: ":", maxSplits: 1).map(String.init)
            if parts.count == 2 {
                let key = parts[0].trimmingCharacters(in: .whitespaces)
                let value = parts[1].trimmingCharacters(in: .whitespaces)
                config[key] = value
            }
        }
        
        return DatabaseConfig(
            host: config["host"] ?? "localhost",
            port: Int(config["port"] ?? "3306") ?? 3306,
            username: config["username"] ?? "",
            password: config["password"] ?? "",
            database: config["database"] ?? ""
        )
    }
}

// MARK: - Preview
#Preview {
    DatabaseDetail()
        .environmentObject(AppProvider())
        .environmentObject(DatabaseProvider())
}
