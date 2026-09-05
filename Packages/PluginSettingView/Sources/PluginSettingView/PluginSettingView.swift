import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderSettingView

/// 设置视图管理器插件（KernelCore 生态）。
///
/// 以自研 `SettingViewManager` 替换 `ProviderFactory` 预注册的
/// `DefaultSettingViewProviding`，提供带结构化日志的 `SettingViewProviding` 实现。
///
/// 执行顺序：order = 3
/// - 必须先于所有通过 `SettingViewProviding.addEntries(_:)` 贡献设置入口的插件
///   （如 `PluginSettingGeneral` order=200、`PluginToolManager` order=6 等），
///   确保后续插件 `resolveProvider((any SettingViewProviding).self)` 拿到的是本插件的实现。
@MainActor
public final class PluginSettingView: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.setting-view", category: "Plugin")
    public nonisolated static let emoji = "⚙️"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.setting-view"
    public let order = 3
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.setting-view",
        name: "Plugin Setting View",
        description: "",
        category: .general,
        stage: .stable,
        policy: .required
    )

    /// 本插件装配的 SettingViewManager 实现。
    private var manager: SettingViewManager?

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        let manager = SettingViewManager()
        self.manager = manager

        // 0. 复制先前已注册实现中已有的数据，避免数据丢失。
        //    在注销前解析当前的 SettingViewProviding，把已注入的入口和选中状态迁移到本实现。
        if let old = kernel.resolveProvider((any SettingViewProviding).self) {
            if !old.entries.isEmpty {
                manager.registerEntries(old.entries)
            }
            if !old.projectDetailSections.isEmpty {
                manager.addProjectDetailSections(old.projectDetailSections)
            }
            // 读取先前的选中 id，保持设置 Provider 替换前后的页面状态。
            if let oldSelection = old.selectedEntryID {
                manager.selectEntry(id: oldSelection)
            }
            if Self.verbose {
                Self.logger.info("\(Self.t)copied \(old.entries.count) existing entries from previous SettingViewProviding")
            }
        }

        // 1. 注销 ProviderFactory 预注册的默认实现（避免 providerAlreadyRegistered）。
        kernel.unregisterProvider((any SettingViewProviding).self)

        // 2. 注册本插件实现。消费者直接观察 SettingViewProviding 的状态变化。
        try kernel.registerProvider((any SettingViewProviding).self, manager)

        if Self.verbose {
            Self.logger.info("\(Self.t)registered SettingViewManager as SettingViewProviding")
        }
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        manager = nil
        // 内核会按插件归属自动撤回 onBoot 注册的 Provider，无需手动处理。
    }
}
