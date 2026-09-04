import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderCommit
import ProviderStatusBar
import SwiftUI

// MARK: - File Info SuperPlugin

/// 文件信息插件：状态栏显示当前选中文件路径，点击弹出文件操作
/// （对齐旧版 PluginFileInfo）。
@MainActor
public final class FileInfoPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.file-info", category: "FileInfo")
    nonisolated public static let emoji = "📄"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.file-info"
    public let order = 37
    public let dependencies = ["com.coffic.gitok.plugin.commit-detail"]
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.file-info",
        name: "File Info",
        description: "Show the selected file path and file actions in the status bar",
        category: .project,
        stage: .stable,
        policy: .alwaysOn
    )

    static let itemID = "com.coffic.gitok.plugin.file-info.id"

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let statusBar = kernel.resolveProvider((any StatusBarProviding).self) else {
            Self.logger.error("\(self.t)StatusBarProviding not registered; skip file info item")
            return
        }
        guard let commit = kernel.resolveProvider((any CommitDetailProviding).self) else {
            Self.logger.error("\(self.t)CommitDetailProviding not registered; skip file info item")
            return
        }

        statusBar.addStatusBarItems([
            StatusBarItem(
                id: Self.itemID,
                title: "File Info",
                placement: .leading,
                order: 19
            ) {
                FileInfoTile(commit: commit)
            },
        ])
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any StatusBarProviding).self)?
            .removeStatusBarItems(ids: [Self.itemID])
    }
}
