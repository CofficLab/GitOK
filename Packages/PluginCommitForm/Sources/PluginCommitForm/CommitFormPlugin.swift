import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderCommitForm
import ProviderProjects

// MARK: - Commit Form SuperPlugin

/// 提交表单插件
///
/// 订阅 `CommitFormProviding` 的提交事件：一次提交（或提交并推送）成功后，
/// 向 `ProjectProviding` 发送 `dataChanged` 信号，让 commit 列表、工作区状态、
/// diff 等消费方刷新展示。
///
/// 提交表单的 UI（`CommitFormView`）由 PluginCommitDetail 在详情区顶部嵌入，
/// 状态与提交动作的权威源是 `CommitFormProviding`。
@MainActor
public final class CommitFormPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.commit-form", category: "CommitForm")
    nonisolated public static let emoji = "📝"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.commit-form"
    /// 依赖项目管理服务先启动。
    public let order = 22
    public let dependencies = ["com.coffic.lumi.plugin.projects"]
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.commit-form",
        name: "Commit Form",
        description: "Commit workflow: staged message, category, style and commit & push",
        category: .project,
        stage: .stable,
        policy: .disabled
    )

    private var formHandle: (any CommitFormObserverHandle)?

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

        formHandle = form.addObserver { [weak projects] event in
            guard case .committed = event else { return }
            // 提交成功后通知消费方刷新（commit 列表 / 工作区状态 / diff）。
            projects?.notifyDataChanged()
        }
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        formHandle?.cancel()
        formHandle = nil
    }
}
