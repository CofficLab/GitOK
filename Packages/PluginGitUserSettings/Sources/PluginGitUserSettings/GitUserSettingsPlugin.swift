import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderGitUser
import ProviderProjects
import ProviderSettingView
import ProviderStorage
import ProviderToast
import ProviderDocsView

// MARK: - Git User Settings SuperPlugin

/// Git 用户设置插件。
///
/// 作为「用户预设管理」的具体实现方（对齐「一个 provider 负责预设管理、
/// 一个插件具体实现」的架构）：
/// - 预设的管理统一交给内核解析出的 `GitUserPresetProviding`（由 ProviderGitUser 定义）；
/// - 若宿主尚未注册该 provider，本插件用 `DefaultGitUserPresetProvider` 兜底注册
///   （数据落在 `StorageProviding.pluginDataDirectory(for:)` 指向的目录），
///   保证设置页开箱即用；
/// - 在设置窗口注册「User Info」入口（person.circle），提供 Git 用户预设的
///   管理与写入当前项目 git 配置的能力（对齐旧版 PluginGitUserSettings）。
@MainActor
public final class GitUserSettingsPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.git-user-settings", category: "GitUserSettings")
    nonisolated public static let emoji = "👤"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.git-user-settings"
    /// 预设 Provider 必须先于 WorktreeClean（order 22）装配。
    public let order = 20
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.git-user-settings",
        name: "Git User Settings",
        description: "Manage Git user presets and apply them to the current project",
        category: .project,
        stage: .stable,
        policy: .required
    )

    /// 由本插件注册进内核的默认 provider（宿主未注册时）；用于 onShutdown 时反注册。
    private var registeredDefaultProvider: DefaultGitUserPresetProvider?

    public init() {}

    public func onRegister(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any DocsViewProviding).self)?.addAbout(
            DocsEntry(id: id, name: metadata.name) { GitUserSettingsAboutView() }
        )
    }

    public func onUnregister(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any DocsViewProviding).self)?.removeEntries(id: id)
    }

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

        // 预设管理统一交给 ProviderGitUser；宿主未注册时用默认实现兜底并注册。
        let provider: any GitUserPresetProviding
        if let resolved = kernel.resolveProvider((any GitUserPresetProviding).self) {
            provider = resolved
        } else {
            let directory: URL
            if let storage = kernel.resolveProvider((any StorageProviding).self) {
                directory = storage.pluginDataDirectory(for: id)
            } else {
                directory = FileManager.default.homeDirectoryForCurrentUser
                    .appendingPathComponent("Library/Application Support/GitOK/com.coffic.gitok.plugin.git-user-settings")
            }
            let defaultProvider = DefaultGitUserPresetProvider(directory: directory)
            try kernel.registerProvider((any GitUserPresetProviding).self, defaultProvider)
            registeredDefaultProvider = defaultProvider
            provider = defaultProvider
        }

        let entry = SettingEntryItem(
            id: "userInfo",
            title: LumiPluginLocalization.string("User Info", bundle: .module),
            systemImage: "person.circle",
            order: 20
        ) { [projects, provider, toast] in
            GitUserInfoSettingView(projects: projects, provider: provider, toast: toast)
        }
        settings.addEntries([entry])
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any SettingViewProviding).self)?
            .removeEntries(ids: ["userInfo"])
        if registeredDefaultProvider != nil {
            kernel.unregisterProvider((any GitUserPresetProviding).self)
            registeredDefaultProvider = nil
        }
    }
}
