import Foundation
import KernelCore
import KitGit
import KitSuperLog
import os
import ProviderProjects
import ProviderStatusBar
import SwiftUI

// MARK: - Git LFS SuperPlugin

/// Git LFS 插件：状态栏图标，检测 git-lfs 与大文件，可初始化
/// （对齐旧版 PluginGitLFS 的核心能力）。
@MainActor
public final class GitLFSPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.git-lfs", category: "GitLFS")
    nonisolated public static let emoji = "🗄️"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.git-lfs"
    public let order = 49
    public let dependencies = ["com.coffic.lumi.plugin.projects"]
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.git-lfs",
        name: "Git LFS",
        description: "Git LFS status and large file recommendations",
        category: .project,
        stage: .stable,
        policy: .disabled
    )

    static let itemID = "com.coffic.gitok.plugin.git-lfs.id"

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let statusBar = kernel.resolveProvider((any StatusBarProviding).self) else {
            Self.logger.error("\(self.t)StatusBarProviding not registered; skip lfs item")
            return
        }
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error("\(self.t)ProjectProviding not registered; skip lfs item")
            return
        }

        statusBar.addStatusBarItems([
            StatusBarItem(
                id: Self.itemID,
                title: "Git LFS",
                placement: .leading,
                order: 25
            ) {
                GitLFSStatusTile(projects: projects)
            },
        ])
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any StatusBarProviding).self)?
            .removeStatusBarItems(ids: [Self.itemID])
    }
}
