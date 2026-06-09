/// BranchPlugin 内部使用的上下文，由 GitOKPluginContext 转换而来。
///
/// 所有子视图通过此结构体获取内核数据，不再依赖 SwiftUI Environment。
public struct BranchPluginContext: Sendable {
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