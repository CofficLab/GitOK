import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderProjects
import ProviderStatusBar
import ProviderTheme
import SwiftUI

// MARK: - Status Bar SuperPlugin

/// 状态栏插件
///
/// 在 `onBoot` 阶段解析 `StatusBarProviding`，向窗口底部状态栏注入项目信息
/// （leading）与主题切换（trailing）入口，验证状态栏 Provider 的插件扩展模型。
///
/// 遵循 Lumi 架构：Provider 声明能力（`StatusBarProviding`），插件通过
/// `addStatusBarItems` 追加自己的贡献，不覆盖其他插件的状态栏项。
@MainActor
public final class StatusBarPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.status-bar", category: "StatusBar")
    nonisolated public static let emoji = "📊"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.status-bar"
    public let order = 30
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.status-bar",
        name: "Status Bar",
        description: "Window bottom status bar: current project + theme switch",
        category: .system,
        stage: .stable,
        policy: .alwaysOn
    )

    /// 状态栏项 id（onShutdown 时按前缀撤回）。
    public static let itemPrefix = "com.coffic.gitok.plugin.status-bar"

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let statusBar = kernel.resolveProvider((any StatusBarProviding).self) else {
            Self.logger.error("\(self.t)StatusBarProviding not registered; skip status bar items")
            return
        }
        statusBar.addStatusBarItems(buildItems(kernel: kernel))
        if Self.verbose {
            Self.logger.debug("\(self.t)injected status bar items")
        }
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any StatusBarProviding).self)?
            .removeStatusBarItems(ids: [
                "\(Self.itemPrefix).project",
                "\(Self.itemPrefix).theme",
            ])
    }

    // MARK: - Items

    private func buildItems(kernel: KernelCoreContainer) -> [StatusBarItem] {
        let projects = kernel.resolveProvider((any ProjectProviding).self)
        let theme = kernel.resolveProvider((any ThemeProviding).self)

        var items: [StatusBarItem] = []

        if let projects {
            items.append(StatusBarItem(
                id: "\(Self.itemPrefix).project",
                title: "Current Project",
                placement: .leading,
                order: 10
            ) {
                ProjectStatusBarItem(projects: projects)
            })
        }

        if let theme {
            items.append(StatusBarItem(
                id: "\(Self.itemPrefix).theme",
                title: "Switch Theme",
                placement: .trailing,
                order: 10
            ) {
                ThemeStatusBarItem(theme: theme)
            })
        }

        return items
    }
}
