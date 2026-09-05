import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderProjects
import ProviderStatusBar
import ProviderWorkspaceScene
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
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.file-info",
        name: "File Info",
        description: "Show the selected file path and file actions in the status bar",
        category: .project,
        stage: .stable,
        policy: .disabled
    )

    static let itemID = "com.coffic.gitok.plugin.file-info.id"

    private var sceneViewModel: WorkspaceSceneVisibilityViewModel?
    private var sceneObserver: FileInfoSceneObserver?

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let statusBar = kernel.resolveProvider((any StatusBarProviding).self) else {
            Self.logger.error("\(self.t)StatusBarProviding not registered; skip file info item")
            return
        }
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error("\(self.t)ProjectProviding not registered; skip file info item")
            return
        }
        guard let scene = kernel.resolveProvider((any WorkspaceSceneProviding).self) else {
            Self.logger.error("\(self.t)WorkspaceSceneProviding not registered; skip scene wiring")
            return
        }
        let sceneViewModel = WorkspaceSceneVisibilityViewModel(targetScene: .git)
        self.sceneViewModel = sceneViewModel
        let sceneCapability = FileInfoSceneCapabilityAdapter(scene: scene)
        self.sceneObserver = FileInfoSceneObserver(capability: sceneCapability, viewModel: sceneViewModel)

        statusBar.addStatusBarItems([
            StatusBarItem(
                id: Self.itemID,
                title: FileInfoLocalization.string("File Info", bundle: .module),
                placement: .leading,
                order: 19
            ) {
                WorkspaceSceneVisibilityView(viewModel: sceneViewModel) {
                    FileInfoTile(projects: projects)
                }
            },
        ])
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        sceneObserver?.cancel()
        sceneObserver = nil
        sceneViewModel = nil
        kernel.resolveProvider((any StatusBarProviding).self)?
            .removeStatusBarItems(ids: [Self.itemID])
    }
}
