import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderProjects
import ProviderStatusBar
import ProviderWorkspaceScene
import SwiftUI

// MARK: - Git Smart Merge SuperPlugin

/// 智能合并插件：状态栏箭头图标，弹出分支合并表单
/// （对齐旧版 PluginGitSmartMerge）。
@MainActor
public final class GitSmartMergePlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.git-smart-merge", category: "GitSmartMerge")
    nonisolated public static let emoji = "🔀"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.git-smart-merge"
    public let order = 48
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.git-smart-merge",
        name: "Smart Merge",
        description: "Merge branches from the status bar",
        category: .project,
        stage: .stable,
        policy: .required
    )

    static let itemID = "com.coffic.gitok.plugin.git-smart-merge.id"

    private var sceneViewModel: WorkspaceSceneVisibilityViewModel?
    private var sceneObserver: GitSmartMergeSceneObserver?

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let statusBar = kernel.resolveProvider((any StatusBarProviding).self) else {
            Self.logger.error("\(self.t)StatusBarProviding not registered; skip merge item")
            return
        }
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error("\(self.t)ProjectProviding not registered; skip merge item")
            return
        }
        guard let scene = kernel.resolveProvider((any WorkspaceSceneProviding).self) else {
            Self.logger.error("\(self.t)WorkspaceSceneProviding not registered; skip scene wiring")
            return
        }
        let sceneViewModel = WorkspaceSceneVisibilityViewModel(targetScene: .git)
        self.sceneViewModel = sceneViewModel
        let sceneCapability = GitSmartMergeSceneCapabilityAdapter(scene: scene)
        self.sceneObserver = GitSmartMergeSceneObserver(capability: sceneCapability, viewModel: sceneViewModel)

        statusBar.addStatusBarItems([
            StatusBarItem(
                id: Self.itemID,
                title: GitSmartMergeLocalization.string("Merge", bundle: .module),
                placement: .leading,
                order: 24
            ) {
                WorkspaceSceneVisibilityView(viewModel: sceneViewModel) {
                    MergeStatusTile(projects: projects)
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
