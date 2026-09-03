import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderProjects
import ProviderSettingView
import ProviderStorage
import ProviderToast

// MARK: - Git User Settings SuperPlugin

/// Git 用户设置插件
///
/// 在设置窗口注册「User Info」入口（person.circle），提供 Git 用户预设
/// 的管理与写入当前项目 git 配置的能力（对齐旧版 PluginGitUserSettings）。
@MainActor
public final class GitUserSettingsPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.git-user-settings", category: "GitUserSettings")
    nonisolated public static let emoji = "👤"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.git-user-settings"
    public let order = 40
    public let dependencies = ["com.coffic.lumi.plugin.projects", "com.coffic.lumi.plugin.setting-view"]
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.git-user-settings",
        name: "Git User Settings",
        description: "Manage Git user presets and apply them to the current project",
        category: .project,
        stage: .stable,
        policy: .alwaysOn
    )

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let settings = kernel.resolveProvider((any SettingViewProviding).self) else {
            Self.logger.error("\(self.t)SettingViewProviding not registered; skip user settings entry")
            return
        }
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error("\(self.t)ProjectProviding not registered; skip user settings entry")
            return
        }

        let toast = kernel.resolveProvider((any ToastProviding).self)
        let directory: URL
        if let storage = kernel.resolveProvider((any StorageProviding).self) {
            directory = storage.pluginDataDirectory(for: "GitUserSettings")
        } else {
            directory = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Application Support/GitOK/GitUserSettings")
        }
        let store = GitUserConfigStore(directory: directory)

        let entry = SettingEntryItem(
            id: "userInfo",
            title: "User Info",
            systemImage: "person.circle",
            order: 20
        ) { [projects, store, toast] in
            GitUserInfoSettingView(projects: projects, store: store, toast: toast)
        }
        settings.addEntries([entry])
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any SettingViewProviding).self)?
            .removeEntries(ids: ["userInfo"])
    }
}
