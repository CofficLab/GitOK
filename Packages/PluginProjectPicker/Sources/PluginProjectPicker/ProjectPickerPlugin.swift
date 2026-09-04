import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderProjects
import ProviderToolbar
import SwiftUI

// MARK: - Project Picker SuperPlugin

/// 项目选择器插件：在工具栏 leading 区注入项目下拉选择器
/// （对齐旧版 PluginProjectPicker）。
@MainActor
public final class ProjectPickerPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.project-picker", category: "ProjectPicker")
    nonisolated public static let emoji = "📁"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.project-picker"
    public let order = 35
    public let dependencies = ["com.coffic.lumi.plugin.projects"]
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.project-picker",
        name: "Project Picker",
        description: "Switch the current project from the toolbar",
        category: .project,
        stage: .stable,
        policy: .disabled
    )

    static let itemID = "com.coffic.gitok.plugin.project-picker.id"

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let toolbar = kernel.resolveProvider((any ToolbarProviding).self) else {
            Self.logger.error("\(self.t)ToolbarProviding not registered; skip project picker")
            return
        }
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error("\(self.t)ProjectProviding not registered; skip project picker")
            return
        }

        toolbar.addToolbarItems([
            ToolbarItem(
                id: Self.itemID,
                title: "Project Picker",
                placement: .leading,
                category: .project,
                order: 5
            ) {
                ProjectPickerView(projects: projects)
            },
        ])
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any ToolbarProviding).self)?
            .removeToolbarItems(ids: [Self.itemID])
    }
}
