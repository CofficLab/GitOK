import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderProjects
import ProviderStatusBar
import SwiftUI

// MARK: - Git Branch Status SuperPlugin

/// 分支状态插件：在状态栏显示当前分支名（对齐旧版 PluginGitBranch）。
@MainActor
public final class GitBranchStatusPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.git-branch-status", category: "GitBranchStatus")
    nonisolated public static let emoji = "🌿"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.git-branch-status"
    public let order = 32
    public let dependencies = ["com.coffic.lumi.plugin.projects"]
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.git-branch-status",
        name: "Git Branch Status",
        description: "Show the current branch in the status bar",
        category: .project,
        stage: .stable,
        policy: .alwaysOn
    )

    static let itemID = "com.coffic.gitok.plugin.git-branch-status.id"

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let statusBar = kernel.resolveProvider((any StatusBarProviding).self) else {
            Self.logger.error("\(self.t)StatusBarProviding not registered; skip branch status item")
            return
        }
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error("\(self.t)ProjectProviding not registered; skip branch status item")
            return
        }

        statusBar.addStatusBarItems([
            StatusBarItem(
                id: Self.itemID,
                title: "Current Branch",
                placement: .leading,
                order: 15
            ) {
                BranchStatusTile(projects: projects)
            },
        ])
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any StatusBarProviding).self)?
            .removeStatusBarItems(ids: [Self.itemID])
    }
}
