import Foundation
import KernelCore
import KitGit
import LumiLoggingKit
import os
import ProviderAutoPush
import ProviderCommitForm
import ProviderGit
import ProviderProjects
import ProviderStorage
import ProviderToolbar
import ProviderWorkspaceScene
import SwiftUI
import ProviderDocsView

// MARK: - Git Auto Push SuperPlugin

/// 自动推送插件：工具栏右侧图标显示开关状态，点击配置；提交成功后自动推送
/// （对齐旧版 PluginGitAutoPush）。
@MainActor
public final class GitAutoPushPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.git-auto-push", category: "GitAutoPush")
    nonisolated public static let emoji = "🚀"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.git-auto-push"
    public let order = 39
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.git-auto-push",
        name: "Auto Push",
        description: pluginLocalization.string("Automatically push after each commit"),
        category: .project,
        stage: .stable,
        policy: .alwaysOn
    )

    /// 工具栏项 id（onShutdown 时按 id 撤回）。
    public static let toolbarItemID = "com.coffic.gitok.plugin.git-auto-push.toolbar"

    private var sceneViewModel: WorkspaceSceneVisibilityViewModel?
    private var sceneObserver: GitAutoPushSceneObserver?

    public init() {}

    public func onRegister(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any DocsViewProviding).self)?.addAbout(
            DocsEntry(id: id, name: metadata.name) { GitAutoPushAboutView() }
        )
    }

    public func onUnregister(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any DocsViewProviding).self)?.removeEntries(id: id)
    }

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let toolbar = kernel.resolveProvider((any ToolbarProviding).self) else {
            Self.logger.error("\(self.t)ToolbarProviding not registered; skip auto push item")
            return
        }
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error("\(self.t)ProjectProviding not registered; skip auto push item")
            return
        }
        guard let git = kernel.resolveProvider((any GitProviding).self) else {
            Self.logger.error("\(self.t)GitProviding not registered; skip auto push item")
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
                Self.autoPush(projectURL: project.url, git: git)
            }
        }

        // 工具栏右侧：自动推送开关入口（排在 OpenIn 按钮之前、设置齿轮之后）。
        toolbar.addToolbarItems([
            ToolbarItem(
                id: Self.toolbarItemID,
                title: pluginLocalization.string("Auto Push"),
                placement: .trailing,
                category: .project,
                order: 130
            ) {
                WorkspaceSceneVisibilityView(viewModel: sceneViewModel) {
                    AutoPushToolbarButton(
                        projects: projects,
                        autoPush: autoPushProvider
                    )
                }
            },
        ])
        if Self.verbose {
            Self.logger.debug("\(self.t)injected auto push button into toolbar")
        }
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        sceneObserver?.cancel()
        sceneObserver = nil
        sceneViewModel = nil
        kernel.resolveProvider((any ToolbarProviding).self)?
            .removeToolbarItems(ids: [Self.toolbarItemID])
    }

    private nonisolated static func autoPush(projectURL: URL, git: any GitProviding) {
        Task.detached(priority: .userInitiated) {
            do {
                guard git.currentBranch(in: projectURL) != nil else { return }
                _ = try git.push(in: projectURL)
            } catch {
                Self.logger.error("Auto push failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}
