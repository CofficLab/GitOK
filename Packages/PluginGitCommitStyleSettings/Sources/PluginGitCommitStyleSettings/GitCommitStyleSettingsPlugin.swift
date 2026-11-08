import Foundation
import KernelCore
import LumiLoggingKit
import os
import ProviderCommitForm
import ProviderStorage
import ProviderSettingView
import SwiftUI
import ProviderDocsView

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
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.git-commit-style-settings",
        name: "Commit Style",
        description: pluginLocalization.string("Choose the global default commit message style"),
        category: .project,
        stage: .stable,
        policy: .alwaysOn
    )

    public init() {}

    public func onRegister(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any DocsViewProviding).self)?.addAbout(
            DocsEntry(id: id, name: metadata.name) { GitCommitStyleSettingsAboutView() }
        )
    }

    public func onUnregister(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any DocsViewProviding).self)?.removeEntries(id: id)
    }

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let settings = kernel.resolveProvider((any SettingViewProviding).self) else {
            Self.logger.error("\(self.t)SettingViewProviding not registered; skip commit style entry")
            return
        }

        // 全局默认风格落在插件数据目录（不再用 UserDefaults）；
        // 注入目录时会一次性导入旧版 UserDefaults 中的全局风格。
        // 该值与提交表单共享，因此使用 GlobalCommitStyleStore 约定的目录 id。
        if let storage = kernel.resolveProvider((any StorageProviding).self) {
            CommitStyleStore.configure(
                directory: storage.pluginDataDirectory(
                    for: GlobalCommitStyleStore.pluginDataDirectoryID
                )
            )
        } else {
            Self.logger.error("\(self.t)StorageProviding not registered; commit style falls back to in-memory store")
        }

        settings.addEntries([
            SettingEntryItem(
                id: "commitStyle",
                title: pluginLocalization.string("Commit Style"),
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
