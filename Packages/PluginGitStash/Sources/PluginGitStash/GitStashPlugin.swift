import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderProjects
import ProviderStatusBar
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
    public let dependencies = ["com.coffic.lumi.plugin.projects"]
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.git-stash",
        name: "Stash",
        description: "Manage git stashes from the status bar",
        category: .project,
        stage: .stable,
        policy: .disabled
    )

    static let itemID = "com.coffic.gitok.plugin.git-stash.id"

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

        statusBar.addStatusBarItems([
            StatusBarItem(
                id: Self.itemID,
                title: GitStashLocalization.string("Stash", bundle: .module),
                placement: .leading,
                order: 17,
                sceneScope: .git
            ) {
                StashStatusTile(projects: projects)
            },
        ])
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any StatusBarProviding).self)?
            .removeStatusBarItems(ids: [Self.itemID])
    }
}
