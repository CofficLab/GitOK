import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderProjects
import ProviderStatusBar
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
    public let dependencies = ["com.coffic.lumi.plugin.projects"]
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.git-remote-repository",
        name: "Remote Repository",
        description: "Manage remote repositories from the status bar",
        category: .project,
        stage: .stable,
        policy: .alwaysOn
    )

    static let itemID = "com.coffic.gitok.plugin.git-remote-repository.id"

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

        statusBar.addStatusBarItems([
            StatusBarItem(
                id: Self.itemID,
                title: "Remote Repository",
                placement: .leading,
                order: 23
            ) {
                RemoteRepositoryStatusButton(projects: projects)
            },
        ])
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any StatusBarProviding).self)?
            .removeStatusBarItems(ids: [Self.itemID])
    }
}
