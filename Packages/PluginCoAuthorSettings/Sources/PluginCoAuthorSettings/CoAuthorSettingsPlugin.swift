import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderCoAuthor
import ProviderProjects
import ProviderSettingView
import ProviderStorage
import ProviderToast
import ProviderDocsView

// MARK: - CoAuthor Settings SuperPlugin

/// 协作者设置插件。
///
/// 作为「协作者管理」的具体实现方（对齐「一个 provider 负责管理、
/// 一个插件具体实现」的架构）：
/// - 管理统一交给内核解析出的 `CoAuthorProviding`（由 ProviderCoAuthor 定义）；
/// - 若宿主尚未注册该 provider，本插件用 `DefaultCoAuthorProvider` 兜底注册
///   （数据落在 `StorageProviding.pluginDataDirectory(for:)` 指向的目录），
///   保证设置页开箱即用；
/// - 在设置窗口注册「Co-Authors」入口（person.2），提供协作者的管理能力。
@MainActor
public final class CoAuthorSettingsPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.coauthor-settings", category: "CoAuthorSettings")
    nonisolated public static let emoji = "👥"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.coauthor-settings"
    /// 预设 Provider 必须先于 WorktreeClean（order 22）装配。
    public let order = 20
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.coauthor-settings",
        name: "Co-Author Settings",
        description: "Manage co-authors for commit trailers",
        category: .project,
        stage: .stable,
        policy: .required
    )

    /// 由本插件注册进内核的默认 provider（宿主未注册时）；用于 onShutdown 时反注册。
    private var registeredDefaultProvider: DefaultCoAuthorProvider?

    public init() {}

    public func onRegister(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any DocsViewProviding).self)?.addAbout(
            DocsEntry(id: id, name: metadata.name) { CoAuthorSettingsAboutView() }
        )
    }

    public func onUnregister(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any DocsViewProviding).self)?.removeEntries(id: id)
    }

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let settings = kernel.resolveProvider((any SettingViewProviding).self) else {
            Self.logger.error("\(self.t)SettingViewProviding not registered; skip co-author settings entry")
            return
        }

        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error("\(self.t)ProjectProviding not registered; skip co-author settings entry")
            return
        }

        let toast = kernel.resolveProvider((any ToastProviding).self)

        // 管理统一交给 ProviderCoAuthor；宿主未注册时用默认实现兜底并注册。
        let provider: any CoAuthorProviding
        if let resolved = kernel.resolveProvider((any CoAuthorProviding).self) {
            provider = resolved
        } else {
            let directory: URL
            if let storage = kernel.resolveProvider((any StorageProviding).self) {
                directory = storage.pluginDataDirectory(for: id)
            } else {
                directory = FileManager.default.homeDirectoryForCurrentUser
                    .appendingPathComponent("Library/Application Support/GitOK/com.coffic.gitok.plugin.coauthor-settings")
            }
            let defaultProvider = DefaultCoAuthorProvider(directory: directory)
            try kernel.registerProvider((any CoAuthorProviding).self, defaultProvider)
            registeredDefaultProvider = defaultProvider
            provider = defaultProvider
        }

        let entry = SettingEntryItem(
            id: "coAuthors",
            title: CoAuthorSettingsLocalization.string("Co-Authors", bundle: .module),
            systemImage: "person.2",
            order: 21
        ) { [provider, toast] in
            CoAuthorSettingView(projects: projects, provider: provider, toast: toast)
        }
        settings.addEntries([entry])
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any SettingViewProviding).self)?
            .removeEntries(ids: ["coAuthors"])
        if registeredDefaultProvider != nil {
            kernel.unregisterProvider((any CoAuthorProviding).self)
            registeredDefaultProvider = nil
        }
    }
}
