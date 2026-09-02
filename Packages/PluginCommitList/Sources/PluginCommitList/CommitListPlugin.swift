import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderProjects
import ProviderRailView
import ProviderRootView
import SwiftUI

// MARK: - Commit List SuperPlugin

/// Commit 列表插件
///
/// 在 `onBoot` 阶段解析 `RootViewProviding` 与 `ProjectProviding`，
/// 向根布局注入一个 Rail 视图（显示在侧边栏右侧），展示当前打开项目的
/// commit 列表。
///
/// 遵循 Lumi 架构：RootView 提供 Rail 槽位（`setRailView`），插件在装配
/// 阶段注入自己的 Rail 视图；同时注销默认空实现 `RailViewProviding`，
/// 避免宿主装配流程用空 Rail 覆盖本插件的注入。
@MainActor
public final class CommitListPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.commit-list", category: "CommitList")
    nonisolated public static let emoji = "🕑"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.commit-list"
    /// 依赖项目管理服务先启动。
    public let order = 20
    public let dependencies = ["com.coffic.lumi.plugin.projects"]
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.commit-list",
        name: "Commit List",
        description: "Rail view showing the commit history of the current project",
        category: .project,
        stage: .stable,
        policy: .alwaysOn
    )

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let rootView = kernel.resolveProvider((any RootViewProviding).self) else {
            Self.logger.error("\(self.t)RootViewProviding not registered; skip rail injection")
            return
        }
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error("\(self.t)ProjectProviding not registered; skip rail injection")
            return
        }

        // 注销默认空 RailViewProviding，避免 ViewFactory 用空 Rail 覆盖本插件的注入。
        kernel.unregisterProvider((any RailViewProviding).self)
        rootView.setRailView(AnyView(CommitRailView(projects: projects)))
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any RootViewProviding).self)?.setRailView(nil)
    }
}
