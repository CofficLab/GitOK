import KernelCore
import KitSuperLog
import os
import ProviderGit
import ProviderGitRepositoryWatch
import ProviderProjectLanguages
import ProviderProjects

/// Publishes local repository language statistics for project-facing views.
@MainActor
public final class ProjectLanguagesPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(
        subsystem: "com.coffic.gitok.plugin.project-languages",
        category: "ProjectLanguages"
    )
    nonisolated public static let emoji = "🧩"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.project-languages"
    public let order = 21
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.project-languages",
        name: "Project Languages",
        description: "Provides local programming language statistics for the current project",
        category: .project,
        stage: .stable,
        policy: .required
    )

    private var provider: LocalProjectLanguagesProvider?
    private var projectsHandle: (any ProjectProvidingObserverHandle)?
    private var gitWatchHandle: (any GitRepositoryWatchingObserverHandle)?

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error("ProjectProviding is unavailable; skip project language provider")
            return
        }

        let provider = LocalProjectLanguagesProvider()
        self.provider = provider
        try kernel.registerProvider((any ProjectLanguagesProviding).self, provider)
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
                guard let provider, let projects else { return }
                switch event {
                case .refsChanged:
                    provider.refresh(for: projects.currentProject?.url)
                default:
                    break
                }
            }
        }
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        projectsHandle?.cancel()
        projectsHandle = nil
        gitWatchHandle?.cancel()
        gitWatchHandle = nil
        provider = nil
        kernel.unregisterProvider((any ProjectLanguagesProviding).self)
    }
}
