import Foundation

struct APIConfig: Codable {
    var requests: [APIRequest]
    
    static func load(from project: Project) -> APIConfig {
        let configPath = URL(fileURLWithPath: project.path)
            .appendingPathComponent(".apirunner")
            .appendingPathComponent("config.json")
        
        if let data = try? Data(contentsOf: configPath),
           let config = try? JSONDecoder().decode(APIConfig.self, from: data) {
            return config
        }
        
        return APIConfig(requests: [])
    }
    
    func save(to project: Project) throws {
        let configDir = URL(fileURLWithPath: project.path)
            .appendingPathComponent(".apirunner")
        
        if !FileManager.default.fileExists(atPath: configDir.path) {
            try FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)
        }
        
        let configPath = configDir.appendingPathComponent("config.json")
        let data = try JSONEncoder().encode(self)
        try data.write(to: configPath)
    }
} 