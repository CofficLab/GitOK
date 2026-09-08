import KernelCore
import KitSuperLog
import os
import ProviderActivityHeatmap
import ProviderGit
import ProviderGitRepositoryWatch
import ProviderProjects
import ProviderStorage

/// Provides local Git activity data for UI plugins.
@MainActor
public final class ActivityHeatmapPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.activity-heatmap", category: "ActivityHeatmap")
    nonisolated public static let emoji = "📊"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.activity-heatmap"
    public let order = 20
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.activity-heatmap",
        name: "Activity Heatmap Data",
        description: "Provides cached local Git activity data for workspace views",
        category: .project,
        stage: .stable,
        policy: .required
    )

    private var provider: LocalActivityHeatmapProvider?
    private var projectsHandle: (any ProjectProvidingObserverHandle)?
    private var gitWatchHandle: (any GitRepositoryWatchingObserverHandle)?

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let git = kernel.resolveProvider((any GitProviding).self),
              let projects = kernel.resolveProvider((any ProjectProviding).self),
              let storage = kernel.resolveProvider((any StorageProviding).self) else {
            Self.logger.error("\(self.t)required providers are unavailable; skip activity heatmap data")
            return
        }

        let provider = LocalActivityHeatmapProvider(
            directory: storage.pluginDataDirectory(for: id),
            git: git
        )
        self.provider = provider
        try kernel.registerProvider((any ActivityHeatmapProviding).self, provider)

        provider.refresh(for: projects.currentProject?.url)
        projectsHandle = projects.addObserver { [weak provider, weak projects] event in
            guard let provider, let projects else { return }
            switch event {
            case .selectionChanged, .dataChanged:
                provider.refresh(for: projects.currentProject?.url)
            default:
                break
            }
        }

        if let gitWatch = kernel.resolveProvider((any GitRepositoryWatching).self) {
            gitWatchHandle = gitWatch.addObserver { [weak provider, weak projects] event in
                guard case .workingTreeChanged = event,
                      let provider,
                      let projects else { return }
                provider.refresh(for: projects.currentProject?.url)
            }
        }
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        projectsHandle?.cancel()
        projectsHandle = nil
        gitWatchHandle?.cancel()
        gitWatchHandle = nil
        provider = nil
        kernel.unregisterProvider((any ActivityHeatmapProviding).self)
    }
}
