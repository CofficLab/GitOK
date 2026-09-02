import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderProjects
import ProviderToolbar
import SwiftUI

// MARK: - OpenIn SuperPlugin

/// Open 系列插件
///
/// 复刻旧版 11 个 `PluginOpen*` 插件（OpenFinder / OpenTerminal / OpenVSCode /
/// OpenCursor / OpenXcode / OpenTrae / OpenAntigravity / OpenGitHubDesktop /
/// OpenKiro / OpenLumi / OpenRemote）：在 `onBoot` 阶段解析 `ToolbarProviding`
/// 与 `ProjectProviding`，向工具栏右侧注入一系列「在当前项目中打开」的
/// 应用图标按钮。未安装的应用自动隐藏；Remote 读取 git remote 用浏览器打开。
///
/// 遵循 Lumi 架构：Provider 声明能力（`ToolbarProviding`），插件通过
/// `addToolbarItems` 追加贡献，不覆盖其他插件的工具栏项。
@MainActor
public final class OpenInPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.open-in", category: "OpenIn")
    nonisolated public static let emoji = "📂"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.open-in"
    public let order = 35
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.open-in",
        name: "Open In",
        description: "Open the current project in Finder / Terminal / VS Code / editors / remote",
        category: .project,
        stage: .stable,
        policy: .alwaysOn
    )

    /// 工具栏项 id 前缀（onShutdown 时按前缀撤回）。
    public static let itemPrefix = "com.coffic.gitok.plugin.open-in"

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let toolbar = kernel.resolveProvider((any ToolbarProviding).self) else {
            Self.logger.error("\(self.t)ToolbarProviding not registered; skip open-in items")
            return
        }
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error("\(self.t)ProjectProviding not registered; skip open-in items")
            return
        }

        let items = OpenTarget.allCases.compactMap { target -> ProviderToolbar.ToolbarItem? in
            // 未安装的应用不占用工具栏空间（Remote 始终可用）。
            guard target.isAlwaysAvailable || AppLauncher.isInstalled(target) else { return nil }
            return ProviderToolbar.ToolbarItem(
                id: "\(Self.itemPrefix).\(target.rawValue)",
                title: target.helpText,
                placement: .trailing,
                category: .project,
                order: target.toolbarOrder
            ) {
                OpenInButton(target: target, projects: projects)
            }
        }
        toolbar.addToolbarItems(items)
        if Self.verbose {
            Self.logger.debug("\(self.t)injected \(items.count) open-in toolbar items")
        }
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        let ids = Set(OpenTarget.allCases.map { "\(Self.itemPrefix).\($0.rawValue)" })
        kernel.resolveProvider((any ToolbarProviding).self)?
            .removeToolbarItems(ids: ids)
    }
}
