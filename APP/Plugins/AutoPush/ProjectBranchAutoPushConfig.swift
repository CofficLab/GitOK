import Foundation

/// 项目分支自动推送配置模型
struct ProjectBranchAutoPushConfig: Codable, Identifiable, Equatable {
    let id: String
    let projectPath: String
    let branchName: String
    var isEnabled: Bool
    var lastModified: Date
    var lastPushedAt: Date?

    init(projectPath: String, branchName: String, isEnabled: Bool = false, lastModified: Date = Date(), lastPushedAt: Date? = nil) {
        self.id = "\(projectPath)://\(branchName)"
        self.projectPath = projectPath
        self.branchName = branchName
        self.isEnabled = isEnabled
        self.lastModified = lastModified
        self.lastPushedAt = lastPushedAt
    }

    var projectTitle: String {
        URL(fileURLWithPath: projectPath).lastPathComponent
    }
}
