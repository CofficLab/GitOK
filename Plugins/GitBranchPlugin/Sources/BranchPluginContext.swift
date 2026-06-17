import Foundation
import GitOKCoreKit

public struct GitBranchPluginContext: Sendable {
    public let projectURL: URL?
    public let branchName: String?
    public let isGitRepository: Bool

    public init(
        projectURL: URL? = nil,
        branchName: String? = nil,
        isGitRepository: Bool = false
    ) {
        self.projectURL = projectURL
        self.branchName = branchName
        self.isGitRepository = isGitRepository
    }

    @MainActor
    public init(_ context: GitOKPluginContext) {
        self.projectURL = context.projectURL
        self.branchName = context.branchName
        self.isGitRepository = context.isGitRepository
    }
}
