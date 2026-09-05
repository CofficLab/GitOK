import Foundation
import KernelCore
import KitGit
import KitSuperLog
import os
import ProviderAutoPush
import ProviderCommitForm
import ProviderProjects
import ProviderStatusBar
import ProviderStorage
import ProviderWorkspaceScene
import SwiftUI

// MARK: - Git Auto Push SuperPlugin

/// 自动推送插件：状态栏图标显示开关状态，点击配置；提交成功后自动推送
/// （对齐旧版 PluginGitAutoPush）。
@MainActor
public final class GitAutoPushPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.git-auto-push", category: "GitAutoPush")
    nonisolated public static let emoji = "🚀"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.git-auto-push"
    public let order = 39
    public let dependencies = [
        "com.coffic.gitok.plugin.projects",
        "com.coffic.gitok.plugin.commit-form",
        "com.coffic.gitok.plugin.storage",
    ]
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.git-auto-push",
        name: "Auto Push",
        description: "Automatically push after each commit",
        category: .project,
        stage: .stable,
        policy: .disabled
    )

    static let itemID = "com.coffic.gitok.plugin.git-auto-push.id"

    private var sceneViewModel: WorkspaceSceneVisibilityViewModel?
    private var sceneObserver: GitAutoPushSceneObserver?

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let statusBar = kernel.resolveProvider((any StatusBarProviding).self) else {
            Self.logger.error("\(self.t)StatusBarProviding not registered; skip auto push item")
            return
        }
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error("\(self.t)ProjectProviding not registered; skip auto push item")
            return
        }
        guard let scene = kernel.resolveProvider((any WorkspaceSceneProviding).self) else {
            Self.logger.error("\(self.t)WorkspaceSceneProviding not registered; skip scene wiring")
            return
        }
        let sceneViewModel = WorkspaceSceneVisibilityViewModel(targetScene: .git)
        self.sceneViewModel = sceneViewModel
        let sceneCapability = GitAutoPushSceneCapabilityAdapter(scene: scene)
        self.sceneObserver = GitAutoPushSceneObserver(capability: sceneCapability, viewModel: sceneViewModel)
        guard let storage = kernel.resolveProvider((any StorageProviding).self) else {
            Self.logger.error("\(self.t)StorageProviding not registered; skip auto push item")
            return
        }
        // AutoPushProviding 由本插件注册（ProviderFactory 不注册）。
        let autoPushProvider = DefaultAutoPushProvider(storage: storage)
        try kernel.registerProvider((any AutoPushProviding).self, autoPushProvider)
        Self.logger.info("\(self.t)Registered AutoPushProviding")

        // 提交成功后自动推送。
        if let form = kernel.resolveProvider((any CommitFormProviding).self) {
            form.addObserver { [weak autoPushProvider] event in
                guard case .committed = event,
                      let autoPushProvider,
                      let project = projects.currentProject,
                      autoPushProvider.isEnabled(for: project.url) else { return }
                Self.autoPush(projectURL: project.url)
            }
        }

        statusBar.addStatusBarItems([
            StatusBarItem(
                id: Self.itemID,
                title: LumiPluginLocalization.string("Auto Push", bundle: .module),
                placement: .leading,
                order: 21
            ) {
                WorkspaceSceneVisibilityView(viewModel: sceneViewModel) {
                    AutoPushStatusIcon(
                        projects: projects,
                        autoPush: autoPushProvider
                    )
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

    private nonisolated static func autoPush(projectURL: URL) {
        Task.detached(priority: .userInitiated) {
            do {
                guard GitRefReader.currentBranch(in: projectURL) != nil else { return }
                try GitCommitOperation.push(in: projectURL)
            } catch {
                Self.logger.error("Auto push failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}
