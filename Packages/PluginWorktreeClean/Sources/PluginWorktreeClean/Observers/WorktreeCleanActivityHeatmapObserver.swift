import ProviderActivityHeatmap
import ProviderProjects

/// Bridges activity-provider and project events into the Worktree Clean view model.
@MainActor
final class WorktreeCleanActivityHeatmapObserver {
    private let capability: any WorktreeCleanActivityHeatmapCapability
    private let viewModel: WorktreeCleanActivityHeatmapViewModel
    private var projectsHandle: (any ProjectProvidingObserverHandle)?
    private var activityHandle: (any ActivityHeatmapObserverHandle)?

    init(
        capability: any WorktreeCleanActivityHeatmapCapability,
        projects: any ProjectProviding,
        viewModel: WorktreeCleanActivityHeatmapViewModel
    ) {
        self.capability = capability
        self.viewModel = viewModel

        activityHandle = capability.addObserver { [weak self] _ in
            guard let self else { return }
            self.viewModel.sync(from: capability)
        }

        projectsHandle = projects.addObserver { [weak self, weak projects] _ in
            guard let self, let projects else { return }
            self.viewModel.handleContextChanged(
                projectURL: projects.currentProject?.url,
                hasSelectedCommit: projects.currentCommit != nil,
                capability: capability
            )
        }

        viewModel.handleContextChanged(
            projectURL: projects.currentProject?.url,
            hasSelectedCommit: projects.currentCommit != nil,
            capability: capability
        )
    }

    func cancel() {
        projectsHandle?.cancel()
        projectsHandle = nil
        activityHandle?.cancel()
        activityHandle = nil
    }
}
