import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderProjects
import ProviderStatusBar
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
    public let dependencies = ["com.coffic.lumi.plugin.projects"]
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.git-conflict-resolver",
        name: "Conflict Resolver",
        description: "Show and list merge conflicts from the status bar",
        category: .project,
        stage: .stable,
        policy: .alwaysOn
    )

    static let itemID = "com.coffic.gitok.plugin.git-conflict-resolver.id"

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

        statusBar.addStatusBarItems([
            StatusBarItem(
                id: Self.itemID,
                title: "Conflict Resolver",
                placement: .leading,
                order: 18
            ) {
                ConflictStatusTile(projects: projects)
            },
        ])
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any StatusBarProviding).self)?
            .removeStatusBarItems(ids: [Self.itemID])
    }
}
