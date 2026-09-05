import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderGitRepositoryWatch
import ProviderProjects

/// Git 仓库监听插件。
///
/// 把 `GitRepositoryWatchProvider`（基于 `FSEventStream` 的真正 `.git` 目录监听）
/// 注册到内核作为 `GitRepositoryWatching` 的唯一实现，并订阅
/// `ProjectProviding` 的选择事件，自动把监听目标同步到当前项目：
/// - 打开项目 → 开始监听该项目的 `.git` 目录；
/// - 切换项目 → 停旧 + 启新；
/// - 关闭项目 → 停止监听。
///
/// 消费方（工作区状态条、commit 列表、分支状态等）通过内核解析
/// `GitRepositoryWatching` 并 `addObserver` 订阅事件，按事件维度精确刷新，
/// 从而能感知外部修改（终端 `git stash` / `git checkout` / 其他工具改仓库）。
///
/// 启动顺序：在 `ProjectsPlugin`（order=0）之后、其他依赖 `ProjectProviding`
/// 的业务插件之前启动（order=5）。
@MainActor
public final class GitRepositoryWatchPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(
        subsystem: "com.coffic.gitok.plugin.git-repository-watch",
        category: "GitRepositoryWatch"
    )
    nonisolated public static let emoji = "📡"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.git-repository-watch"
    /// 在 Projects 插件（order=0）之后启动，其他消费方之前。
    public let order = 5
    public let dependencies = ["com.coffic.lumi.plugin.projects"]
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.git-repository-watch",
        name: "Git Repository Watch",
        description: "Watch .git directory changes and broadcast per-dimension events",
        category: .project,
        stage: .stable,
        policy: .required
    )

    /// 注册到内核的 `GitRepositoryWatching` 实现。
    private var provider: GitRepositoryWatchProvider?

    /// 对 `ProjectProviding` 的订阅句柄（插件卸载时取消）。
    private var projectHandle: (any ProjectProvidingObserverHandle)?

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error(
                "\(self.t)ProjectProviding not registered; skip git repository watch"
            )
            return
        }

        let provider = GitRepositoryWatchProvider()
        self.provider = provider
        try kernel.registerProvider((any GitRepositoryWatching).self, provider)

        // 订阅项目选择事件：切换 / 关闭项目时同步监听目标。
        projectHandle = projects.addObserver { [weak provider, weak projects] event in
            guard case .selectionChanged = event else { return }
            guard let projects, let provider else { return }
            if let url = projects.currentProject?.url {
                provider.startWatching(repositoryURL: url)
            } else {
                provider.stopWatching()
            }
        }

        // 初始状态：如果当前已有项目，立即开始监听。
        if let url = projects.currentProject?.url {
            provider.startWatching(repositoryURL: url)
        }
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        projectHandle?.cancel()
        projectHandle = nil
        provider?.stopWatching()
        provider = nil
        kernel.unregisterProvider((any GitRepositoryWatching).self)
    }
}
