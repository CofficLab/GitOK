import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderCommit
import ProviderCommitForm
import ProviderContentView
import ProviderProjects
import SwiftUI

// MARK: - Commit Detail SuperPlugin

/// Commit 详情插件
///
/// 在 `onBoot` 阶段解析 `CommitDetailProviding` 与 `ContentViewProviding`，
/// 通过 ContentView 槽位（RootView 的主内容入口）注册主内容视图。
/// 视图订阅 CommitDetailProviding：当 Commit 列表（侧边栏 Rail）选中某条
/// commit 后，主内容区展示该 commit 的变动（文件列表 + unified diff）。
///
/// 遵循 Lumi 架构：RootView 通过 `ContentViewProviding` 提供主内容槽位，
/// 插件在装配阶段通过 `setContentView(_:)` 注入自己的内容视图。
@MainActor
public final class CommitDetailPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.commit-detail", category: "CommitDetail")
    nonisolated public static let emoji = "🔍"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.commit-detail"
    /// 依赖项目与 commit 列表先启动（选中状态由列表写入）。
    public let order = 21
    public let dependencies = ["com.coffic.lumi.plugin.projects", "com.coffic.gitok.plugin.commit-list"]
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.commit-detail",
        name: "Commit Detail",
        description: "Main content view showing the changes of the selected commit",
        category: .project,
        stage: .stable,
        policy: .disabled
    )

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let contentView = kernel.resolveProvider((any ContentViewProviding).self) else {
            Self.logger.error("\(self.t)ContentViewProviding not registered; skip content injection")
            return
        }
        guard let detail = kernel.resolveProvider((any CommitDetailProviding).self) else {
            Self.logger.error("\(self.t)CommitDetailProviding not registered; skip content injection")
            return
        }
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error("\(self.t)ProjectProviding not registered; skip content injection")
            return
        }

        let form = kernel.resolveProvider((any CommitFormProviding).self)
        contentView.setContentView(
            AnyView(CommitDetailView(detail: detail, projects: projects, form: form))
        )
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any ContentViewProviding).self)?.setContentView(nil)
    }
}
