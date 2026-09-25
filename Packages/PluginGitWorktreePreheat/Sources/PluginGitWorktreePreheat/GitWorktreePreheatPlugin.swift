import KernelCore
import KitSuperLog
import os
import ProviderGit
import ProviderGitRepositoryWatch
import ProviderProjects

/// Git 工作区快照预热插件。
///
/// 它是项目管理与 Git Provider 之间的协调层：从内核解析全部项目，
/// 但不把项目依赖下沉到 ProviderGit，也不把后台扫描逻辑放进 UI 插件。
@MainActor
public final class GitWorktreePreheatPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(
        subsystem: "com.coffic.gitok.plugin.git-worktree-preheat",
        category: "GitWorktreePreheat"
    )
    nonisolated public static let emoji = "🔥"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.git-worktree-preheat"
    /// Projects = 0，Git backend = 2，repository watch = 5，预热在其后启动。
    public let order = 10
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.git-worktree-preheat",
        name: "Git Worktree Preheat",
        description: "Preloads working tree snapshots for saved projects",
        category: .project,
        stage: .stable,
        policy: .required
    )

    private var preheater: WorktreeSnapshotPreheater?

    public init() {}

    public func onRegister(kernel: KernelCoreContainer) throws {}

    public func onUnregister(kernel: KernelCoreContainer) throws {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error("\(self.t)ProjectProviding not registered; skip worktree preheat")
            return
        }
        guard let git = kernel.resolveProvider((any GitProviding).self) else {
            Self.logger.error("\(self.t)GitProviding not registered; skip worktree preheat")
            return
        }

        let gitWatch = kernel.resolveProvider((any GitRepositoryWatching).self)
        let preheater = WorktreeSnapshotPreheater(
            projects: projects,
            loadSnapshot: { url, cancellation in
                _ = try git.loadWorktreeSnapshot(in: url, cancellation: cancellation)
            },
            invalidateSnapshot: { url in
                git.invalidateWorktreeSnapshot(in: url)
            },
            gitWatch: gitWatch
        )
        self.preheater = preheater
        preheater.start()
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        preheater?.stop()
        preheater = nil
    }
}
