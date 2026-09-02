import Foundation
import KernelCore
import ProviderSettingView
import SwiftUI
import KitSuperLog
import os

/// 设置 - 插件管理 插件
///
/// 复刻 Lumi 的插件管理功能：在设置窗口注册「插件」入口，
/// 展示已装配插件的列表（名称 / 描述 / 分类 / 启用状态），
/// 并允许启用 / 禁用可配置插件。
///
/// - 入口 id：`plugins`（设置窗口侧边栏靠前显示）。
/// - 本插件 policy 为 `.alwaysOn`，保证插件管理入口自身始终可用，
///   不会被用户误禁用而失去管理能力。
/// - 详情视图通过弱引用内核构造，避免强引用循环；禁用 / 启用
///   调用 `KernelCoreContainer.enablePlugin / disablePlugin`。
@MainActor
public final class PluginManagerPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.plugin-manager", category: "PluginManager")
    nonisolated public static let emoji = "🧩"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.plugin-manager"
    public let order = 110
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.plugin-manager",
        name: "插件管理",
        description: "在设置视图中管理已装配插件的启用状态。",
        category: .system,
        stage: .stable,
        policy: .alwaysOn
    )

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let settings = kernel.resolveProvider((any SettingViewProviding).self) else {
            Self.logger.error("\(self.t)SettingViewProviding not registered; skip plugins entry")
            return
        }

        // 弱引用内核：详情视图仅在内核存活期间访问，避免强引用循环。
        weak var weakKernel = kernel
        let entry = SettingEntryItem(
            id: "plugins",
            title: "插件",
            systemImage: "puzzlepiece.extension",
            order: 10
        ) { [weak weakKernel] in
            if let weakKernel {
                PluginManagementView(kernel: weakKernel)
            } else {
                EmptyView()
            }
        }
        settings.addEntries([entry])
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any SettingViewProviding).self)?
            .removeEntries(ids: ["plugins"])
    }
}
