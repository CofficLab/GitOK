import ProviderGitRepositoryWatch
import ProviderProjects

/// GitBranchStatus 展示当前项目及仓库 HEAD 变化所需的最小能力。
@MainActor
protocol GitBranchStatusCapability: AnyObject {
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

/// 将内核 Provider 收窄成分支状态插件自己的能力边界。
@MainActor
final class GitBranchStatusCapabilityAdapter: GitBranchStatusCapability {
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
