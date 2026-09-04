import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderProjects
import ProviderSettingView
import SwiftUI

// MARK: - Git Repository Settings SuperPlugin

/// 仓库设置插件：在设置窗口注册「Repository Settings」入口
/// （对齐旧版 PluginGitRepositorySettings）。
@MainActor
public final class GitRepositorySettingsPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.git-repository-settings", category: "GitRepositorySettings")
    nonisolated public static let emoji = "📁"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.git-repository-settings"
    public let order = 42
    public let dependencies = [
        "com.coffic.lumi.plugin.setting-view",
        "com.coffic.lumi.plugin.projects",
    ]
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.git-repository-settings",
        name: "Repository Settings",
        description: "Inspect the current repository and manage remotes",
        category: .project,
        stage: .stable,
        policy: .disabled
    )

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let settings = kernel.resolveProvider((any SettingViewProviding).self) else {
            Self.logger.error("\(self.t)SettingViewProviding not registered; skip repository settings entry")
            return
        }
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error("\(self.t)ProjectProviding not registered; skip repository settings entry")
            return
        }

        settings.addEntries([
            SettingEntryItem(
                id: "repository",
                title: "Repository Settings",
                systemImage: "folder.badge.gearshape",
                order: 10
            ) { [projects] in
                RepositorySettingView(projects: projects)
            },
        ])
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any SettingViewProviding).self)?
            .removeEntries(ids: ["repository"])
    }
}
