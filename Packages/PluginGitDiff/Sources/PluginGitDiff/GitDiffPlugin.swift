import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderCommit
import ProviderRootView
import SwiftUI

// MARK: - Git Diff SuperPlugin

/// Git Diff 插件
///
/// 在 `onBoot` 阶段解析 `RootViewProviding` 与 `CommitDetailProviding`，
/// 通过 RootView 的右侧面板槽位（trailing pane）注册 diff 视图。
/// 视图订阅 `CommitDetailProviding`：
/// - `selectedCommit` + `selectedFile` + `selectedProjectURL` 变化时，
///   异步加载该文件在该 commit 中的 unified diff；
/// - 用旧版同款渲染组件 `MagicDiffView` 展示（git 原生 diff 文本）。
///
/// 遵循 Lumi 架构：RootView 通过 `setTrailingPane(_:)` 提供右侧面板槽位，
/// 插件在装配阶段注入自己的内容视图。
@MainActor
public final class GitDiffPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.git-diff", category: "GitDiff")
    nonisolated public static let emoji = "⇄"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.git-diff"
    /// 在 commit-detail 之后启动（文件选择由 commit-detail 的文件列表写入 Provider）。
    public let order = 30
    public let dependencies = ["com.coffic.gitok.plugin.commit-detail"]
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.git-diff",
        name: "Git Diff",
        description: "Trailing pane showing the diff of the selected file in the selected commit",
        category: .project,
        stage: .stable,
        policy: .alwaysOn
    )

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let rootView = kernel.resolveProvider((any RootViewProviding).self) else {
            Self.logger.error("\(self.t)RootViewProviding not registered; skip trailing pane injection")
            return
        }
        guard let detail = kernel.resolveProvider((any CommitDetailProviding).self) else {
            Self.logger.error("\(self.t)CommitDetailProviding not registered; skip trailing pane injection")
            return
        }

        let pane = RootTrailingPane(
            id: "\(id).trailing",
            minWidth: 320,
            idealWidth: 420,
            maxWidth: .infinity,
            isVisible: true,
            content: AnyView(GitDiffPaneView(detail: detail))
        )
        rootView.setTrailingPane(pane)
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any RootViewProviding).self)?.setTrailingPane(nil)
    }
}
