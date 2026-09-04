import Foundation
import KernelCore
import KitGit
import KitSuperLog
import os
import ProviderProjects
import ProviderStatusBar
import SwiftUI

// MARK: - Git Submodule SuperPlugin

/// 子模块插件：状态栏图标，显示子模块列表并可更新
/// （对齐旧版 PluginGitSubmodule 的核心能力）。
@MainActor
public final class GitSubmodulePlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.git-submodule", category: "GitSubmodule")
    nonisolated public static let emoji = "📦"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.git-submodule"
    public let order = 50
    public let dependencies = ["com.coffic.lumi.plugin.projects"]
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.git-submodule",
        name: "Submodule",
        description: "Git submodule status and updates",
        category: .project,
        stage: .stable,
        policy: .disabled
    )

    static let itemID = "com.coffic.gitok.plugin.git-submodule.id"

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let statusBar = kernel.resolveProvider((any StatusBarProviding).self) else {
            Self.logger.error("\(self.t)StatusBarProviding not registered; skip submodule item")
            return
        }
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error("\(self.t)ProjectProviding not registered; skip submodule item")
            return
        }

        statusBar.addStatusBarItems([
            StatusBarItem(
                id: Self.itemID,
                title: "Submodule",
                placement: .leading,
                order: 26
            ) {
                SubmoduleStatusTile(projects: projects)
            },
        ])
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any StatusBarProviding).self)?
            .removeStatusBarItems(ids: [Self.itemID])
    }
}
