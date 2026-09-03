import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderProjects
import ProviderStatusBar
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
    public let dependencies = ["com.coffic.lumi.plugin.projects"]
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.git-ignore",
        name: "Git Ignore",
        description: "View the .gitignore file from the status bar",
        category: .project,
        stage: .stable,
        policy: .alwaysOn
    )

    static let itemID = "com.coffic.gitok.plugin.git-ignore.id"

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

        statusBar.addStatusBarItems([
            StatusBarItem(
                id: Self.itemID,
                title: "Git Ignore",
                placement: .leading,
                order: 20
            ) {
                GitIgnoreStatusIcon(projects: projects)
            },
        ])
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any StatusBarProviding).self)?
            .removeStatusBarItems(ids: [Self.itemID])
    }
}
