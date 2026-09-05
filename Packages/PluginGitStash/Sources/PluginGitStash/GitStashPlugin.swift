import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderProjects
import ProviderStatusBar
import ProviderWorkspaceScene
import SwiftUI

// MARK: - Git Stash SuperPlugin

/// Stash 插件：状态栏显示 stash 数，点击弹出 stash 管理面板
/// （对齐旧版 PluginGitStash）。
@MainActor
public final class GitStashPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.git-stash", category: "GitStash")
    nonisolated public static let emoji = "📦"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.git-stash"
    public let order = 34
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.git-stash",
        name: "Stash",
        description: "Manage git stashes from the status bar",
        category: .project,
        stage: .stable,
        policy: .disabled
    )

    static let itemID = "com.coffic.gitok.plugin.git-stash.id"

    private var sceneViewModel: WorkspaceSceneVisibilityViewModel?
    private var sceneObserver: GitStashSceneObserver?

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let statusBar = kernel.resolveProvider((any StatusBarProviding).self) else {
            Self.logger.error("\(self.t)StatusBarProviding not registered; skip stash item")
            return
        }
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error("\(self.t)ProjectProviding not registered; skip stash item")
            return
        }
        guard let scene = kernel.resolveProvider((any WorkspaceSceneProviding).self) else {
            Self.logger.error("\(self.t)WorkspaceSceneProviding not registered; skip scene wiring")
            return
        }
        let sceneViewModel = WorkspaceSceneVisibilityViewModel(targetScene: .git)
        self.sceneViewModel = sceneViewModel
        let sceneCapability = GitStashSceneCapabilityAdapter(scene: scene)
        self.sceneObserver = GitStashSceneObserver(capability: sceneCapability, viewModel: sceneViewModel)

        statusBar.addStatusBarItems([
            StatusBarItem(
                id: Self.itemID,
                title: GitStashLocalization.string("Stash", bundle: .module),
                placement: .leading,
                order: 17
            ) {
                WorkspaceSceneVisibilityView(viewModel: sceneViewModel) {
                    StashStatusTile(projects: projects)
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
