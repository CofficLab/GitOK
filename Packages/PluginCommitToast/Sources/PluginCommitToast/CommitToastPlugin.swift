import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderProjects
import ProviderToast
import SwiftUI

// MARK: - Commit Toast SuperPlugin

/// Commit 通知插件：观察 `ProjectProviding` 的 commit 选择事件并给出 toast 反馈。
///
/// 「当前 commit」等选择状态由 `ProjectProviding` 统一维护。本插件在 `onBoot`
/// 阶段订阅其 `commitSelectionChanged` 事件：选中 commit 发生变化（含切换
/// 项目时清空选择）时，通过 `ToastProviding` 发出瞬时通知，让用户感知主内容区
/// 展示的 commit 已变化。
///
/// 遵循 Lumi 架构：插件只观察外部事件并叠加体验，不修改 Provider 状态。
@MainActor
public final class CommitToastPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.commit-toast", category: "CommitToast")
    public let id = "com.coffic.gitok.plugin.commit-toast"
    /// 在 ToastSuperPlugin（order 10）之后、CommitListPlugin（order 20）之前启动：
    /// 先订阅 commit 选择事件，保证选择发生即收到通知。
    public let order = 15
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.commit-toast",
        name: "Commit Toast",
        description: "Notify via toast when the selected commit changes",
        category: .project,
        stage: .stable,
        policy: .disabled
    )

    /// ProjectProviding 的订阅句柄（onShutdown 时取消）。
    private var projectsHandle: (any ProjectProvidingObserverHandle)?

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error("\(self.t)ProjectProviding not registered; commit changes will not notify")
            return
        }
        let toast = kernel.resolveProvider((any ToastProviding).self)
        if toast == nil {
            Self.logger.error("\(self.t)ToastProviding not registered; commit changes will not notify")
        }

        projectsHandle = projects.addObserver { [weak toast, weak projects] event in
            guard case .commitSelectionChanged = event, let projects else { return }
            if let commit = projects.currentCommit {
                toast?.show(
                    "已选择提交",
                    detail: commit.shortHash,
                    style: .info
                )
            } else {
                toast?.show(
                    "已清除提交选择",
                    style: .info
                )
            }
        }
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        projectsHandle?.cancel()
        projectsHandle = nil
    }
}
