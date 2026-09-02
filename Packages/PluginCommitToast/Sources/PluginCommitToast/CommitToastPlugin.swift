import Foundation
import KernelCore
import KitGit
import KitSuperLog
import os
import ProviderCommit
import ProviderToast
import SwiftUI

// MARK: - Commit Toast SuperPlugin

/// Commit 通知插件：实现 `CommitDetailProviding` 并提供 toast 反馈。
///
/// 宿主默认注册的 `CommitDetailProviding`（`DefaultCommitDetailProvider`）
/// 只是纯状态容器。本插件在 `onBoot` 中用带 toast 的实现替换它：
/// 选中 commit 发生变化（切换项目时清空选择）时，通过 `ToastProviding`
/// 发出瞬时通知，让用户感知主内容区展示的 commit 已变化。
///
/// 遵循 Lumi 架构：Provider 契约由宿主提供默认实现，业务插件按需替换
/// 并叠加能力（与 `ToastSuperPlugin` 替换 `DefaultToastProviding` 同理）。
@MainActor
public final class CommitToastPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.commit-toast", category: "CommitToast")
    public let id = "com.coffic.gitok.plugin.commit-toast"
    /// 需在 Toast 插件之后启动（onBoot 时 ToastProviding 已替换为真实状态机）。
    public let order = 80
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.commit-toast",
        name: "Commit Toast",
        description: "Notify via toast when the selected commit changes",
        category: .project,
        stage: .stable,
        policy: .alwaysOn
    )

    /// 内部实现：状态 + 观察者由 `DefaultCommitDetailProvider` 提供，
    /// 本插件只叠加 toast 通知。
    private var provider: ToastCommitDetailProvider?

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        let toast = kernel.resolveProvider((any ToastProviding).self)
        if toast == nil {
            Self.logger.error("\(self.t)ToastProviding not registered; commit changes will not notify")
        }

        let provider = ToastCommitDetailProvider(toast: toast)
        self.provider = provider

        // 替换宿主默认的纯状态实现。
        kernel.unregisterProvider((any CommitDetailProviding).self)
        try kernel.registerProvider((any CommitDetailProviding).self, provider)
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        // 保留实现对象（PluginCommitList 等已解析的引用仍有效）；不恢复默认。
    }
}

// MARK: - ToastCommitDetailProvider

/// `CommitDetailProviding` 的 toast 增强实现。
///
/// 委托 `DefaultCommitDetailProvider` 维护选中状态与观察者广播，仅在选择
/// 状态真正发生变化后叠加一条 toast 通知。
@MainActor
public final class ToastCommitDetailProvider: CommitDetailProviding {
    private let inner = DefaultCommitDetailProvider()
    private weak var toast: (any ToastProviding)?

    public init(toast: (any ToastProviding)?) {
        self.toast = toast
    }

    public var selectedCommit: GitCommit? { inner.selectedCommit }
    public var selectedProjectURL: URL? { inner.selectedProjectURL }

    @discardableResult
    public func addObserver(
        _ callback: @escaping (CommitDetailEvent) -> Void
    ) -> any CommitDetailObserverHandle {
        inner.addObserver(callback)
    }

    public func selectCommit(_ commit: GitCommit, in projectURL: URL) {
        let hadSelection = inner.selectedCommit != nil
        inner.selectCommit(commit, in: projectURL)
        // 仅当选择确实发生变化（且非切换项目时的清空）才通知。
        guard !hadSelection || inner.selectedCommit?.hash != commit.hash else { return }
        toast?.show(
            "已选择提交",
            detail: commit.shortHash,
            style: .info
        )
    }

    public func clearSelection() {
        guard inner.selectedCommit != nil else { return }
        inner.clearSelection()
        toast?.show(
            "已清除提交选择",
            style: .info
        )
    }
}
