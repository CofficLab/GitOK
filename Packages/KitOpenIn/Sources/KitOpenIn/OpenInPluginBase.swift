import Foundation
import KernelCore
import ProviderProjects
import ProviderToolbar
import SwiftUI

/// Open 系列插件基类
///
/// 一个「打开目标」对应一个插件（复刻旧版 11 个 `PluginOpen*` 插件）。
/// 子类只需指定 `OpenTarget`，本基类完成其余装配：
/// - `id` / `metadata` / `order` 由 target 派生；
/// - `onBoot` 解析 `ToolbarProviding` + `ProjectProviding`，向工具栏右侧
///   注入一个按钮（未安装的应用自动跳过；Remote 始终可用）；
/// - `onShutdown` 撤回按钮。
@MainActor
open class OpenInPluginBase: SuperPlugin {
    /// 本插件负责的打开目标。
    public let target: OpenTarget

    public init(target: OpenTarget) {
        self.target = target
    }

    // MARK: - Plugin Identity

    open var pluginID: String { "com.coffic.gitok.plugin.open-\(target.rawValue)" }

    open var pluginCategory: PluginCategory { .project }

    open var pluginDisplayName: String { "Open \(target.displayName)" }

    open var pluginOrder: Int { target.toolbarOrder }

    // MARK: - SuperPlugin

    public var id: String { pluginID }

    public var order: Int { pluginOrder }

    public var metadata: PluginMetadata {
        PluginMetadata(
            id: pluginID,
            name: pluginDisplayName,
            description: "Open the current project folder in \(target.displayName).",
            category: pluginCategory,
            stage: .stable,
            policy: .disabled
        )
    }

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let toolbar = kernel.resolveProvider((any ToolbarProviding).self) else { return }
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else { return }
        // 未安装的应用不占用工具栏空间（Remote 始终可用）。
        guard target.isAlwaysAvailable || AppLauncher.isInstalled(target) else { return }

        toolbar.addToolbarItems([
            ProviderToolbar.ToolbarItem(
                id: "\(pluginID).button",
                title: target.helpText,
                placement: .trailing,
                category: .project,
                order: target.toolbarOrder
            ) {
                OpenInButton(target: self.target, projects: projects)
            },
        ])
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any ToolbarProviding).self)?
            .removeToolbarItems(ids: ["\(pluginID).button"])
    }
}
