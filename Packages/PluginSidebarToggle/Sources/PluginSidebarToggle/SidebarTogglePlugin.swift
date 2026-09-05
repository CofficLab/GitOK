import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderRootView
import ProviderToolbar
import SwiftUI

// MARK: - Sidebar Toggle Plugin

/// Sidebar toggle button plugin
///
/// Injects a leading toolbar button that toggles the visibility of the left sidebar.
/// The button icon changes between `sidebar.leading` (sidebar hidden) and
/// `sidebar.squares.leading` (sidebar visible) to reflect the current state.
///
/// Follows the Lumi architecture: the plugin resolves `RootViewProviding` and
/// `ToolbarProviding` via the kernel, then contributes a toolbar item without
/// overriding other plugins' contributions.
@MainActor
public final class SidebarTogglePlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.sidebar-toggle", category: "SidebarToggle")
    nonisolated public static let emoji = "📐"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.sidebar-toggle"
    public let order = 100
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.sidebar-toggle",
        name: "Sidebar Toggle",
        description: "Toolbar button that toggles the left sidebar visibility",
        category: .system,
        stage: .stable,
        policy: .required
    )

    /// Toolbar item id.
    public static let toolbarItemID = "com.coffic.gitok.plugin.sidebar-toggle.toggleSidebar"

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let toolbar = kernel.resolveProvider((any ToolbarProviding).self) else {
            Self.logger.error("\(self.t)ToolbarProviding not registered; skip sidebar toggle button")
            return
        }
        guard let rootView = kernel.resolveProvider((any RootViewProviding).self) else {
            Self.logger.error("\(self.t)RootViewProviding not registered; skip sidebar toggle button")
            return
        }
        toolbar.addToolbarItems([
            ToolbarItem(
                id: Self.toolbarItemID,
                title: SidebarToggleLocalization.string("Toggle Sidebar", bundle: .module),
                placement: .leading,
                category: .global,
                order: 10
            ) {
                SidebarToggleButtonView(rootView: rootView)
            },
        ])
        if Self.verbose {
            Self.logger.debug("\(self.t)injected sidebar toggle button into toolbar")
        }
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any ToolbarProviding).self)?
            .removeToolbarItems(ids: [Self.toolbarItemID])
    }
}
