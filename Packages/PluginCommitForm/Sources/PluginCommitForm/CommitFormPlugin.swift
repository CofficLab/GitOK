import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderCommitForm
import ProviderContentView
import ProviderGitRepositoryWatch
import ProviderProjects
import ProviderWorkspaceScene
import SwiftUI

// MARK: - Commit Form SuperPlugin

/// 提交表单插件
///
/// 两份职责：
/// 1. 订阅 `CommitFormProviding` 的提交事件：一次提交（或提交并推送）成功后，
///    向 `ProjectProviding` 发送 `dataChanged` 信号，让 commit 列表、工作区状态、
///    diff 等消费方刷新展示。
/// 2. 把 `CommitFormView` 作为一块独立内容贡献到主内容区（`ContentViewProviding`）
///    VStack 的顶部：提交表单 UI 由本插件持有，不再由 CommitDetail 插件内嵌。
///
/// 表单状态与提交动作的权威源是 `CommitFormProviding`。
@MainActor
public final class CommitFormPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.commit-form", category: "CommitForm")
    nonisolated public static let emoji = "📝"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.commit-form"
    /// order 较小，保证项目管理服务（projects，order=0）先启动。
    public let order = 22
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.commit-form",
        name: "Commit Form",
        description: "Commit workflow: staged message, category, style and commit & push",
        category: .project,
        stage: .stable,
        policy: .required
    )

    private var formHandle: (any CommitFormObserverHandle)?
    private var sceneViewModel: WorkspaceSceneVisibilityViewModel?
    private var sceneObserver: CommitFormSceneObserver?

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error("\(self.t)ProjectProviding not registered; skip commit form event wiring")
            return
        }
        guard let form = kernel.resolveProvider((any CommitFormProviding).self) else {
            Self.logger.error("\(self.t)CommitFormProviding not registered; skip commit form event wiring")
            return
        }

        guard let scene = kernel.resolveProvider((any WorkspaceSceneProviding).self) else {
            Self.logger.error("\(self.t)WorkspaceSceneProviding not registered; skip scene wiring")
            return
        }

        let sceneViewModel = WorkspaceSceneVisibilityViewModel(targetScene: .git)
        self.sceneViewModel = sceneViewModel
        let sceneCapability = CommitFormSceneCapabilityAdapter(scene: scene)
        self.sceneObserver = CommitFormSceneObserver(capability: sceneCapability, viewModel: sceneViewModel)

        formHandle = form.addObserver { [weak projects] event in
            guard case .committed = event else { return }
            // 提交成功后通知消费方刷新（commit 列表 / 工作区状态 / diff）。
            projects?.notifyDataChanged()
        }

        // 提交表单 UI 作为独立内容块贡献到主内容区顶部（VStack 中 order 较小置顶）。
        if let contentView = kernel.resolveProvider((any ContentViewProviding).self) {
            // GitRepositoryWatching 可选：未注册（如测试环境）时仅依赖
            // ProjectProviding.dataChanged 刷新；真实运行时由 PluginGitRepositoryWatch 提供，
            // 使外部把工作区改干净后表单也能隐藏。
            let gitWatch = kernel.resolveProvider((any GitRepositoryWatching).self)
            contentView.addContentView(
                AnyView(
                    WorkspaceSceneVisibilityView(viewModel: sceneViewModel) {
                        CommitFormView(projects: projects, form: form, gitWatch: gitWatch)
                    }
                        // Debug 构建下左下角叠加插件名 badge，便于识别内容区来源。
                        .debugPluginBadge(metadata.name)
                ),
                id: "\(id).content",
                order: 10
            )
        } else {
            Self.logger.error("\(self.t)ContentViewProviding not registered; skip content contribution")
        }
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        sceneObserver?.cancel()
        sceneObserver = nil
        sceneViewModel = nil
        formHandle?.cancel()
        formHandle = nil
        kernel.resolveProvider((any ContentViewProviding).self)?
            .removeContentView(id: "\(id).content")
    }
}
