import ProviderProjectLanguages

/// Worktree Clean's narrow view-facing boundary for project language data.
@MainActor
protocol WorktreeCleanProjectLanguagesCapability: AnyObject {
    var currentSnapshot: ProjectLanguagesSnapshot? { get }
    var isLoading: Bool { get }

    @discardableResult
    func addObserver(
        _ callback: @escaping (ProjectLanguagesEvent) -> Void
    ) -> any ProjectLanguagesObserverHandle
}

/// Adapts the kernel provider to the Worktree Clean UI boundary.
@MainActor
final class WorktreeCleanProjectLanguagesCapabilityAdapter: WorktreeCleanProjectLanguagesCapability {
    private let provider: any ProjectLanguagesProviding

    init(provider: any ProjectLanguagesProviding) {
        self.provider = provider
    }

    var currentSnapshot: ProjectLanguagesSnapshot? { provider.currentSnapshot }
    var isLoading: Bool { provider.isLoading }

    @discardableResult
    func addObserver(
        _ callback: @escaping (ProjectLanguagesEvent) -> Void
    ) -> any ProjectLanguagesObserverHandle {
        provider.addObserver(callback)
    }
}
