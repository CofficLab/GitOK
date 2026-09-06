import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderProjects
import ProviderStatusBar
import SwiftUI
import ProviderDocsView

// MARK: - License SuperPlugin

/// LICENSE 插件：状态栏图标，点击查看/创建 LICENSE 内容
/// （对齐旧版 PluginLicense）。
@MainActor
public final class LicensePlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.license", category: "License")
    nonisolated public static let emoji = "📜"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.license"
    public let order = 45
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.license",
        name: "License",
        description: "View or create the LICENSE file",
        category: .project,
        stage: .stable,
        policy: .disabled
    )

    static let itemID = "com.coffic.gitok.plugin.license.id"

    public init() {}

    public func onRegister(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any DocsViewProviding).self)?.addAbout(
            DocsEntry(id: id, name: metadata.name) { LicenseAboutView() }
        )
    }

    public func onUnregister(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any DocsViewProviding).self)?.removeEntries(id: id)
    }

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let statusBar = kernel.resolveProvider((any StatusBarProviding).self) else {
            Self.logger.error("\(self.t)StatusBarProviding not registered; skip license item")
            return
        }
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error("\(self.t)ProjectProviding not registered; skip license item")
            return
        }

        statusBar.addStatusBarItems([
            StatusBarItem(
                id: Self.itemID,
                title: LicenseLocalization.string("License", bundle: .module),
                placement: .leading,
                order: 22
            ) {
                LicenseStatusIcon(projects: projects)
            },
        ])
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any StatusBarProviding).self)?
            .removeStatusBarItems(ids: [Self.itemID])
    }
}
