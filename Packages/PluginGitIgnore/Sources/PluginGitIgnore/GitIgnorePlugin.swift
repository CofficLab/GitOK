import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderProjects
import ProviderStatusBar
import ProviderWorkspaceScene
import SwiftUI

// MARK: - Git Ignore SuperPlugin

/// .gitignore 插件：状态栏图标，点击查看 .gitignore 内容
/// （对齐旧版 PluginGitIgnore）。
@MainActor
public final class GitIgnorePlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.git-ignore", category: "GitIgnore")
    nonisolated public static let emoji = "📝"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.git-ignore"
    public let order = 38
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.git-ignore",
        name: "Git Ignore",
        description: "View the .gitignore file from the status bar",
        category: .project,
        stage: .stable,
        policy: .disabled
    )

    static let itemID = "com.coffic.gitok.plugin.git-ignore.id"

    private var sceneViewModel: WorkspaceSceneVisibilityViewModel?
    private var sceneObserver: GitIgnoreSceneObserver?

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let statusBar = kernel.resolveProvider((any StatusBarProviding).self) else {
            Self.logger.error("\(self.t)StatusBarProviding not registered; skip gitignore item")
            return
        }
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error("\(self.t)ProjectProviding not registered; skip gitignore item")
            return
        }
        guard let scene = kernel.resolveProvider((any WorkspaceSceneProviding).self) else {
            Self.logger.error("\(self.t)WorkspaceSceneProviding not registered; skip scene wiring")
            return
        }
        let sceneViewModel = WorkspaceSceneVisibilityViewModel(targetScene: .git)
        self.sceneViewModel = sceneViewModel
        let sceneCapability = GitIgnoreSceneCapabilityAdapter(scene: scene)
        self.sceneObserver = GitIgnoreSceneObserver(capability: sceneCapability, viewModel: sceneViewModel)

        statusBar.addStatusBarItems([
            StatusBarItem(
                id: Self.itemID,
                title: GitIgnoreLocalization.string("Git Ignore", bundle: .module),
                placement: .leading,
                order: 20
            ) {
                WorkspaceSceneVisibilityView(viewModel: sceneViewModel) {
                    GitIgnoreStatusIcon(projects: projects)
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
