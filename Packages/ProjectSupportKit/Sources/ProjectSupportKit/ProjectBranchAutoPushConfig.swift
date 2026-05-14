import Foundation

public struct ProjectBranchAutoPushConfig: Codable, Identifiable, Equatable {
    public let id: String
    public let projectPath: String
    public let branchName: String
    public var isEnabled: Bool
    public var lastModified: Date
    public var lastPushedAt: Date?

    public init(
        projectPath: String,
        branchName: String,
        isEnabled: Bool = false,
        lastModified: Date = Date(),
        lastPushedAt: Date? = nil
    ) {
        self.id = "\(projectPath)://\(branchName)"
        self.projectPath = projectPath
        self.branchName = branchName
        self.isEnabled = isEnabled
        self.lastModified = lastModified
        self.lastPushedAt = lastPushedAt
    }

    public var projectTitle: String {
        URL(fileURLWithPath: projectPath).lastPathComponent
    }
}
