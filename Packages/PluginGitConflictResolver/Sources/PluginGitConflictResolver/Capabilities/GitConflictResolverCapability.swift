import ProviderGitRepositoryWatch
import ProviderProjects

/// ConflictResolver 读取当前项目并观察仓库状态变化所需的最小能力。
@MainActor
protocol GitConflictResolverCapability: AnyObject {
    var currentProject: Project? { get }

    @discardableResult
    func addProjectObserver(
        _ callback: @escaping (ProjectProvidingEvent) -> Void
    ) -> any ProjectProvidingObserverHandle

    @discardableResult
    func addRepositoryObserver(
        _ callback: @escaping (GitRepositoryWatchingEvent) -> Void
    ) -> (any GitRepositoryWatchingObserverHandle)?
}

/// 将内核 Provider 收窄成冲突解决插件自己的能力边界。
@MainActor
final class GitConflictResolverCapabilityAdapter: GitConflictResolverCapability {
    private let projects: any ProjectProviding
    private let gitWatch: (any GitRepositoryWatching)?

    init(
        projects: any ProjectProviding,
        gitWatch: (any GitRepositoryWatching)?
    ) {
        self.projects = projects
        self.gitWatch = gitWatch
    }

    var currentProject: Project? {
        projects.currentProject
    }

    @discardableResult
    func addProjectObserver(
        _ callback: @escaping (ProjectProvidingEvent) -> Void
    ) -> any ProjectProvidingObserverHandle {
        projects.addObserver(callback)
    }

    @discardableResult
    func addRepositoryObserver(
        _ callback: @escaping (GitRepositoryWatchingEvent) -> Void
    ) -> (any GitRepositoryWatchingObserverHandle)? {
        gitWatch?.addObserver(callback)
    }
}
