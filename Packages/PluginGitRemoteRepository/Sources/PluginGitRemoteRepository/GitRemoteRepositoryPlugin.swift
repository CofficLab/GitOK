import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderProjects
import ProviderStatusBar
import ProviderWorkspaceScene
import SwiftUI

// MARK: - Git Remote Repository SuperPlugin

/// 远程仓库插件：状态栏图标，点击打开远程仓库管理面板
/// （对齐旧版 PluginGitRemoteRepository）。
@MainActor
public final class GitRemoteRepositoryPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.git-remote-repository", category: "GitRemoteRepository")
    nonisolated public static let emoji = "🌐"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.git-remote-repository"
    public let order = 46
    public let dependencies = ["com.coffic.gitok.plugin.projects"]
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.git-remote-repository",
        name: "Remote Repository",
        description: "Manage remote repositories from the status bar",
        category: .project,
        stage: .stable,
        policy: .disabled
    )

    static let itemID = "com.coffic.gitok.plugin.git-remote-repository.id"

    private var sceneViewModel: WorkspaceSceneVisibilityViewModel?
    private var sceneObserver: GitRemoteRepositorySceneObserver?

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let statusBar = kernel.resolveProvider((any StatusBarProviding).self) else {
            Self.logger.error("\(self.t)StatusBarProviding not registered; skip remote item")
            return
        }
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error("\(self.t)ProjectProviding not registered; skip remote item")
            return
        }
        guard let scene = kernel.resolveProvider((any WorkspaceSceneProviding).self) else {
            Self.logger.error("\(self.t)WorkspaceSceneProviding not registered; skip scene wiring")
            return
        }
        let sceneViewModel = WorkspaceSceneVisibilityViewModel(targetScene: .git)
        self.sceneViewModel = sceneViewModel
        let sceneCapability = GitRemoteRepositorySceneCapabilityAdapter(scene: scene)
        self.sceneObserver = GitRemoteRepositorySceneObserver(capability: sceneCapability, viewModel: sceneViewModel)

        statusBar.addStatusBarItems([
            StatusBarItem(
                id: Self.itemID,
                title: GitRemoteRepositoryLocalization.string("Remote Repository", bundle: .module),
                placement: .leading,
                order: 23
            ) {
                WorkspaceSceneVisibilityView(viewModel: sceneViewModel) {
                    RemoteRepositoryStatusButton(projects: projects)
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
