import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderActivity
import ProviderCloneRepository
import ProviderProjects
import ProviderToast
import SwiftUI

// MARK: - Clone Repository SuperPlugin

/// 克隆仓库插件
///
/// 提供克隆仓库能力：实现 `CloneRepositoryProviding`，向内核注册
/// `CloneRepositorySheet` 视图；PluginSidebar 等入口在侧边栏底部
/// 以 sheet 展示该视图。克隆完成后打开项目并提示。
@MainActor
public final class CloneRepositoryPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.clone-repository", category: "CloneRepository")
    nonisolated public static let emoji = "📥"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.clone-repository"
    /// 在侧边栏插件（PluginSidebar, order 10）之前注册 provider，入口按钮才能解析到。
    public let order = 5
    public let dependencies = ["com.coffic.lumi.plugin.projects"]
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.clone-repository",
        name: "Clone Repository",
        description: "Clone a remote repository and add it to your projects",
        category: .project,
        stage: .stable,
        policy: .disabled
    )

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error("\(self.t)ProjectProviding not registered; skip clone repository provider")
            return
        }
        let activity = kernel.resolveProvider((any ActivityProviding).self)
        let toast = kernel.resolveProvider((any ToastProviding).self)

        let provider = CloneRepositorySheetProvider(
            projects: projects,
            activity: activity,
            toast: toast
        )
        try kernel.registerProvider((any CloneRepositoryProviding).self, provider)
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.unregisterProvider((any CloneRepositoryProviding).self)
    }
}

/// `CloneRepositoryProviding` 实现：持有克隆所需依赖，产出 sheet 视图。
@MainActor
public final class CloneRepositorySheetProvider: CloneRepositoryProviding {
    private let projects: any ProjectProviding
    private let activity: (any ActivityProviding)?
    private let toast: (any ToastProviding)?

    public init(
        projects: any ProjectProviding,
        activity: (any ActivityProviding)?,
        toast: (any ToastProviding)?
    ) {
        self.projects = projects
        self.activity = activity
        self.toast = toast
    }

    public func makeCloneSheetView() -> AnyView {
        AnyView(
            CloneRepositorySheet(projects: projects, activity: activity, toast: toast)
        )
    }
}
