import Foundation
import KernelCore
import KitGit
import KitSuperLog
import os
import ProviderProjects
import ProviderStatusBar
import ProviderWorkspaceScene
import SwiftUI

// MARK: - Git LFS SuperPlugin

/// Git LFS 插件：状态栏图标，检测 git-lfs 与大文件，可初始化
/// （对齐旧版 PluginGitLFS 的核心能力）。
@MainActor
public final class GitLFSPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.git-lfs", category: "GitLFS")
    nonisolated public static let emoji = "🗄️"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.git-lfs"
    public let order = 49
    public let dependencies = ["com.coffic.lumi.plugin.projects"]
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.git-lfs",
        name: "Git LFS",
        description: "Git LFS status and large file recommendations",
        category: .project,
        stage: .stable,
        policy: .disabled
    )

    static let itemID = "com.coffic.gitok.plugin.git-lfs.id"

    private var sceneViewModel: WorkspaceSceneVisibilityViewModel?
    private var sceneObserver: GitLFSSceneObserver?

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let statusBar = kernel.resolveProvider((any StatusBarProviding).self) else {
            Self.logger.error("\(self.t)StatusBarProviding not registered; skip lfs item")
            return
        }
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error("\(self.t)ProjectProviding not registered; skip lfs item")
            return
        }
        guard let scene = kernel.resolveProvider((any WorkspaceSceneProviding).self) else {
            Self.logger.error("\(self.t)WorkspaceSceneProviding not registered; skip scene wiring")
            return
        }
        let sceneViewModel = WorkspaceSceneVisibilityViewModel(targetScene: .git)
        self.sceneViewModel = sceneViewModel
        self.sceneObserver = GitLFSSceneObserver(scene: scene, viewModel: sceneViewModel)

        statusBar.addStatusBarItems([
            StatusBarItem(
                id: Self.itemID,
                title: GitLFSLocalization.string("Git LFS", bundle: .module),
                placement: .leading,
                order: 25
            ) {
                WorkspaceSceneVisibilityView(viewModel: sceneViewModel) {
                    GitLFSStatusTile(projects: projects)
                }
            },
        ])
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        sceneObserver?.cancel()
        sceneObserver = nil
        sceneViewModel = nil
        kernel.resolveProvider((any StatusBarProviding).self)?
            .removeStatusBarItems(ids: [Self.itemID])
    }
}
