import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderSettingView
import SwiftUI

// MARK: - Git Commit Style Settings SuperPlugin

/// 提交风格设置插件：在设置窗口注册「Commit Style」入口
/// （对齐旧版 PluginGitCommitStyleSettings）。
@MainActor
public final class GitCommitStyleSettingsPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.git-commit-style-settings", category: "GitCommitStyleSettings")
    nonisolated public static let emoji = "🎨"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.git-commit-style-settings"
    public let order = 43
    public let dependencies = ["com.coffic.lumi.plugin.setting-view"]
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.git-commit-style-settings",
        name: "Commit Style",
        description: "Choose the global default commit message style",
        category: .project,
        stage: .stable,
        policy: .disabled
    )

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let settings = kernel.resolveProvider((any SettingViewProviding).self) else {
            Self.logger.error("\(self.t)SettingViewProviding not registered; skip commit style entry")
            return
        }
        settings.addEntries([
            SettingEntryItem(
                id: "commitStyle",
                title: "Commit Style",
                systemImage: "text.alignleft",
                order: 30
            ) {
                CommitStyleSettingView()
            },
        ])
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any SettingViewProviding).self)?
            .removeEntries(ids: ["commitStyle"])
    }
}
