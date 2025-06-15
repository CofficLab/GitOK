import Foundation
import SwiftData
import SwiftUI

protocol GitUserConfigRepoProtocol: BaseRepo where Entity == GitUserConfig {
    // 基础CRUD操作
    func create(name: String, email: String, isDefault: Bool) throws -> GitUserConfig
    func findByNameAndEmail(_ name: String, _ email: String) throws -> GitUserConfig?
    func findDefault() throws -> GitUserConfig?
    func update(_ config: GitUserConfig) throws
    
    // 查询操作
    func findAll(sortedBy order: SortOrder) throws -> [GitUserConfig]
    func findByName(_ name: String) throws -> [GitUserConfig]
    func findByEmail(_ email: String) throws -> [GitUserConfig]
    
    // 业务操作
    func exists(name: String, email: String) -> Bool
    func setAsDefault(_ config: GitUserConfig) throws
    func clearAllDefaults() throws
    func getConfigCount() throws -> Int
    func getRecentConfigs(limit: Int) throws -> [GitUserConfig]
}

#Preview("App-Big Screen") {
    RootView {
        ContentLayout()
    }
    .frame(width: 1200)
    .frame(height: 1200)
} 