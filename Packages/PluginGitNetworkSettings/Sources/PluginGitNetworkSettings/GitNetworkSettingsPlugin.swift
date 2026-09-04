import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderSettingView
import SwiftUI

// MARK: - Git Network Settings SuperPlugin

/// 网络设置插件：在设置窗口注册「Network」入口（对齐旧版 PluginGitNetworkSettings）。
@MainActor
public final class GitNetworkSettingsPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.git-network-settings", category: "GitNetworkSettings")
    nonisolated public static let emoji = "🌐"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.git-network-settings"
    public let order = 41
    public let dependencies = ["com.coffic.lumi.plugin.setting-view"]
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.git-network-settings",
        name: "Git Network Settings",
        description: "Configure git proxy and SSL settings",
        category: .project,
        stage: .stable,
        policy: .disabled
    )

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let settings = kernel.resolveProvider((any SettingViewProviding).self) else {
            Self.logger.error("\(self.t)SettingViewProviding not registered; skip network settings entry")
            return
        }
        settings.addEntries([
            SettingEntryItem(
                id: "network",
                title: "Network",
                systemImage: "network",
                order: 40
            ) {
                GitNetworkSettingView()
            },
        ])
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any SettingViewProviding).self)?
            .removeEntries(ids: ["network"])
    }
}
