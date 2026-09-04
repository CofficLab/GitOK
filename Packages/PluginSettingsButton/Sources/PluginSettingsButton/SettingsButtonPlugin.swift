import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderSettingView
import ProviderToolbar
import SwiftUI

// MARK: - Settings Button SuperPlugin

/// 设置入口按钮插件
///
/// 在 `onBoot` 阶段解析 `ToolbarProviding`，向工具栏**右上角**（`.trailing`）
/// 注入一个齿轮设置按钮；点击后发布 `SettingViewNavigation.openSettingsNotification`，
/// 由宿主打开设置窗口。
///
/// 遵循 Lumi 架构：Provider 声明能力（`ToolbarProviding`），插件通过
/// `addToolbarItems` 追加自己的贡献，不覆盖其他插件的工具栏项。
@MainActor
public final class SettingsButtonPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.settings-button", category: "SettingsButton")
    nonisolated public static let emoji = "⚙️"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.settings-button"
    public let order = 100
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.settings-button",
        name: "Settings Button",
        description: "Toolbar entry that opens the settings window",
        category: .system,
        stage: .stable,
        policy: .required
    )

    /// 工具栏项 id。
    public static let toolbarItemID = "com.coffic.gitok.plugin.settings-button.openSettings"

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let toolbar = kernel.resolveProvider((any ToolbarProviding).self) else {
            Self.logger.error("\(self.t)ToolbarProviding not registered; skip settings button")
            return
        }
        toolbar.addToolbarItems([
            ToolbarItem(
                id: Self.toolbarItemID,
                title: "Open Settings",
                placement: .trailing,
                category: .global,
                order: 150
            ) {
                SettingsButtonView()
            },
        ])
        if Self.verbose {
            Self.logger.debug("\(self.t)injected settings button into toolbar")
        }
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any ToolbarProviding).self)?
            .removeToolbarItems(ids: [Self.toolbarItemID])
    }
}
