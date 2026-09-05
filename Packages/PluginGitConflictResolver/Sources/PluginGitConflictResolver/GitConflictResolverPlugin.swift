import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderGitRepositoryWatch
import ProviderProjects
import ProviderRootView
import ProviderStatusBar
import ProviderWorkspaceScene
import SwiftUI

// MARK: - Git Conflict Resolver SuperPlugin

/// 冲突解决插件：状态栏显示合并冲突状态，点击弹出冲突文件列表
/// （对齐旧版 PluginGitConflictResolver）。
@MainActor
public final class GitConflictResolverPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.git-conflict-resolver", category: "GitConflictResolver")
    nonisolated public static let emoji = "⚠️"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.git-conflict-resolver"
    public let order = 36
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.git-conflict-resolver",
        name: "Conflict Resolver",
        description: "Show and list merge conflicts from the status bar",
        category: .project,
        stage: .stable,
        policy: .alwaysOn
    )

    static let itemID = "com.coffic.gitok.plugin.git-conflict-resolver.id"
    static let overlayID = "com.coffic.gitok.plugin.git-conflict-resolver.overlay"

    private var sceneViewModel: WorkspaceSceneVisibilityViewModel?
    private var sceneObserver: GitConflictResolverSceneObserver?
    private var conflictViewModel: GitConflictResolverViewModel?
    private var conflictObserver: GitConflictResolverObserver?

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let statusBar = kernel.resolveProvider((any StatusBarProviding).self) else {
            Self.logger.error("\(self.t)StatusBarProviding not registered; skip conflict item")
            return
        }
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error("\(self.t)ProjectProviding not registered; skip conflict item")
            return
        }
        guard let scene = kernel.resolveProvider((any WorkspaceSceneProviding).self) else {
            Self.logger.error("\(self.t)WorkspaceSceneProviding not registered; skip scene wiring")
            return
        }
        guard let rootView = kernel.resolveProvider((any RootViewProviding).self) else {
            Self.logger.error("\(self.t)RootViewProviding not registered; skip conflict overlay")
            return
        }
        let sceneViewModel = WorkspaceSceneVisibilityViewModel(targetScene: .git)
        self.sceneViewModel = sceneViewModel
        let sceneCapability = GitConflictResolverSceneCapabilityAdapter(scene: scene)
        self.sceneObserver = GitConflictResolverSceneObserver(capability: sceneCapability, viewModel: sceneViewModel)
        let gitWatch = kernel.resolveProvider((any GitRepositoryWatching).self)
        let conflictCapability = GitConflictResolverCapabilityAdapter(projects: projects, gitWatch: gitWatch)
        let conflictViewModel = GitConflictResolverViewModel()
        self.conflictViewModel = conflictViewModel
        self.conflictObserver = GitConflictResolverObserver(
            capability: conflictCapability,
            viewModel: conflictViewModel
        )

        rootView.addOverlays([
            RootOverlayItem(id: Self.overlayID, order: 9000) { content in
                ConflictResolverOverlayHost(
                    content: content,
                    projects: projects,
                    viewModel: conflictViewModel
                )
            },
        ])

        statusBar.addStatusBarItems([
            StatusBarItem(
                id: Self.itemID,
                title: LumiPluginLocalization.string("Conflict Resolver", bundle: .module),
                placement: .leading,
                order: 18
            ) {
                WorkspaceSceneVisibilityView(viewModel: sceneViewModel) {
                    ConflictStatusTile(projects: projects, viewModel: conflictViewModel)
                }
            },
        ])
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        conflictViewModel?.dismiss()
        sceneObserver?.cancel()
        sceneObserver = nil
        sceneViewModel = nil
        conflictObserver?.cancel()
        conflictObserver = nil
        conflictViewModel = nil
        kernel.resolveProvider((any StatusBarProviding).self)?
            .removeStatusBarItems(ids: [Self.itemID])
        kernel.resolveProvider((any RootViewProviding).self)?
            .removeOverlays(ids: [Self.overlayID])
    }
}
