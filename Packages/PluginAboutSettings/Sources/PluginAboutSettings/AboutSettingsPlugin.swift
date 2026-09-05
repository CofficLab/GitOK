import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderSettingView
import SwiftUI

// MARK: - About Settings SuperPlugin

/// 关于设置插件：在设置窗口注册「About」入口（对齐旧版 PluginAboutSettings）。
@MainActor
public final class AboutSettingsPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.about-settings", category: "AboutSettings")
    nonisolated public static let emoji = "ℹ️"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.about-settings"
    public let order = 44
    public let dependencies = ["com.coffic.gitok.plugin.setting-view"]
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.about-settings",
        name: "About",
        description: "App version and information",
        category: .system,
        stage: .stable,
        policy: .disabled
    )

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let settings = kernel.resolveProvider((any SettingViewProviding).self) else {
            Self.logger.error("\(self.t)SettingViewProviding not registered; skip about entry")
            return
        }
        settings.addEntries([
            SettingEntryItem(
                id: "about",
                title: AboutSettingsLocalization.string("About", bundle: .module),
                systemImage: "info.circle",
                order: 90
            ) {
                AboutView()
            },
        ])
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any SettingViewProviding).self)?
            .removeEntries(ids: ["about"])
    }
}
