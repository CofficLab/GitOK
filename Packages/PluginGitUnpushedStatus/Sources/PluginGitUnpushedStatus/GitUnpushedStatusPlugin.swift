import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderProjects
import ProviderStatusBar
import ProviderWorkspaceScene
import SwiftUI

// MARK: - Git Unpushed Status SuperPlugin

/// 未推送状态插件：在状态栏显示当前分支相对上游未推送的提交数
/// （对齐旧版 PluginGitUnpushedStatus）。
@MainActor
public final class GitUnpushedStatusPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.git-unpushed-status", category: "GitUnpushedStatus")
    nonisolated public static let emoji = "⬆️"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.git-unpushed-status"
    public let order = 33
    public let dependencies = ["com.coffic.gitok.plugin.projects"]
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.git-unpushed-status",
        name: "Unpushed Status",
        description: "Show the unpushed commit count in the status bar",
        category: .project,
        stage: .stable,
        policy: .disabled
    )

    static let itemID = "com.coffic.gitok.plugin.git-unpushed-status.id"

    private var sceneViewModel: WorkspaceSceneVisibilityViewModel?
    private var sceneObserver: GitUnpushedStatusSceneObserver?

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let statusBar = kernel.resolveProvider((any StatusBarProviding).self) else {
            Self.logger.error("\(self.t)StatusBarProviding not registered; skip unpushed status item")
            return
        }
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error("\(self.t)ProjectProviding not registered; skip unpushed status item")
            return
        }
        guard let scene = kernel.resolveProvider((any WorkspaceSceneProviding).self) else {
            Self.logger.error("\(self.t)WorkspaceSceneProviding not registered; skip scene wiring")
            return
        }
        let sceneViewModel = WorkspaceSceneVisibilityViewModel(targetScene: .git)
        self.sceneViewModel = sceneViewModel
        let sceneCapability = GitUnpushedStatusSceneCapabilityAdapter(scene: scene)
        self.sceneObserver = GitUnpushedStatusSceneObserver(capability: sceneCapability, viewModel: sceneViewModel)

        statusBar.addStatusBarItems([
            StatusBarItem(
                id: Self.itemID,
                title: GitUnpushedStatusLocalization.string("Unpushed Commits", bundle: .module),
                placement: .leading,
                order: 16
            ) {
                WorkspaceSceneVisibilityView(viewModel: sceneViewModel) {
                    UnpushedStatusTile(projects: projects)
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
