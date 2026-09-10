import Foundation
import KernelCore
import KitSuperLog
import LumiUI
import os
import ProviderRailView
import ProviderProjects
import ProviderWorkspaceScene
import SwiftUI
import ProviderDocsView

// MARK: - RailViewPlugin

/// Rail 视图插件：实现 `RailViewProviding` 能力，替换宿主的默认实现。
///
/// 在 `onBoot` 中注销 `ProviderFactory` 注册的 `DefaultRailViewProviding`，
/// 替换为插件自有的 `GitOKRailViewProvider`；其他插件（CommitList 等）
/// 通过 `kernel.resolveProvider(RailViewProviding.self)` 解析到的是本插件
/// 注册的实现，行为与默认实现完全兼容。
///
/// 替换式注册模式与 `RootViewPlugin` 一致：尽早完成替换（`order = 6`），
/// 保证后续插件在 `onBoot` 中 resolve 到的是真实实现。
@MainActor
public final class RailViewPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.rail-view", category: "RailView")
    nonisolated public static let emoji = "📋"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.rail-view"
    /// 必须在所有消费 RailViewProviding 的插件之前启动。
    public let order = 6
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.rail-view",
        name: "Rail View",
        description: "Provides the rail view layout, replacing the default provider",
        category: .core,
        stage: .stable,
        policy: .required
    )

    /// 插件自有的 Rail 视图 Provider，替换默认实现。
    public let provider: GitOKRailViewProvider

    public init() {
        self.provider = GitOKRailViewProvider()
    }

    public func onRegister(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any DocsViewProviding).self)?.addAbout(
            DocsEntry(id: id, name: metadata.name) { RailViewAboutView() }
        )
    }

    public func onUnregister(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any DocsViewProviding).self)?.removeEntries(id: id)
    }

    public func onBoot(kernel: KernelCoreContainer) throws {
        // 替换宿主的默认实现为插件自有实现。
        kernel.unregisterProvider((any RailViewProviding).self)
        try kernel.registerProvider((any RailViewProviding).self, provider)
        if Self.verbose {
            Self.logger.info("\(self.t)Replaced default RailViewProviding with GitOKRailViewProvider")
        }
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        // 恢复默认实现，保证后续流程仍可解析 RailViewProviding。
        kernel.unregisterProvider((any RailViewProviding).self)
        try kernel.registerProvider((any RailViewProviding).self, DefaultRailViewProviding())
        if Self.verbose {
            Self.logger.info("\(self.t)Restored default RailViewProviding")
        }
    }
}
