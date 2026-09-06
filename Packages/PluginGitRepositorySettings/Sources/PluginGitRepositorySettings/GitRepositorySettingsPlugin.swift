import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderGit
import ProviderProjects
import ProviderSettingView
import SwiftUI
import ProviderDocsView

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
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.git-repository-settings",
        name: "Repository Settings",
        description: "Inspect the current repository and manage remotes",
        category: .project,
        stage: .stable,
        policy: .disabled
    )

    public init() {}

    public func onRegister(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any DocsViewProviding).self)?.addAbout(
            DocsEntry(id: id, name: metadata.name) { GitRepositorySettingsAboutView() }
        )
    }

    public func onUnregister(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any DocsViewProviding).self)?.removeEntries(id: id)
    }

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let settings = kernel.resolveProvider((any SettingViewProviding).self) else {
            Self.logger.error("\(self.t)SettingViewProviding not registered; skip repository settings entry")
            return
        }
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error("\(self.t)ProjectProviding not registered; skip repository settings entry")
            return
        }
        guard let git = kernel.resolveProvider((any GitProviding).self) else {
            Self.logger.error("\(self.t)GitProviding not registered; skip repository settings entry")
            return
        }

        settings.addEntries([
            SettingEntryItem(
                id: "repository",
                title: LumiPluginLocalization.string("Repository Settings", bundle: .module),
                systemImage: "folder.badge.gearshape",
                order: 10
            ) { [projects, git] in
                RepositorySettingView(projects: projects, git: git)
            },
        ])
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any SettingViewProviding).self)?
            .removeEntries(ids: ["repository"])
    }
}
