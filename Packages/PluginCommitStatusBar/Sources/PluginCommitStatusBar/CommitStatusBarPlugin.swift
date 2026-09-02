import Foundation
import KernelCore
import KitGit
import KitSuperLog
import LumiUI
import os
import ProviderCommit
import ProviderStatusBar
import SwiftUI

// MARK: - Commit Status Bar SuperPlugin

/// Commit 状态栏插件：在窗口底部状态栏显示当前选中 commit 的 id。
///
/// 订阅 `CommitDetailProviding` 的观察者事件，选中 commit 变化时在
/// 状态栏 leading 区展示其短哈希；未选中时显示占位。
///
/// 遵循 Lumi 架构：Provider 声明能力（`StatusBarProviding`），插件通过
/// `addStatusBarItems` 追加自己的贡献，不覆盖其他插件的状态栏项。
@MainActor
public final class CommitStatusBarPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.commit-status-bar", category: "CommitStatusBar")
    nonisolated public static let emoji = "🌿"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.commit-status-bar"
    /// 在 Commit Toast 插件之后启动（该插件可能替换 CommitDetailProviding 实现）。
    public let order = 81
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.commit-status-bar",
        name: "Commit Status Bar",
        description: "Show the selected commit id in the status bar",
        category: .project,
        stage: .stable,
        policy: .alwaysOn
    )

    static let itemID = "com.coffic.gitok.plugin.commit-status-bar.id"

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let statusBar = kernel.resolveProvider((any StatusBarProviding).self) else {
            Self.logger.error("\(self.t)StatusBarProviding not registered; skip status bar item")
            return
        }
        guard let detail = kernel.resolveProvider((any CommitDetailProviding).self) else {
            Self.logger.error("\(self.t)CommitDetailProviding not registered; skip status bar item")
            return
        }

        statusBar.addStatusBarItems([
            StatusBarItem(
                id: Self.itemID,
                title: "Selected Commit",
                placement: .leading,
                order: 20
            ) {
                CommitStatusBarItem(detail: detail)
            },
        ])
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any StatusBarProviding).self)?
            .removeStatusBarItems(ids: [Self.itemID])
    }
}

// MARK: - Commit Status Bar Item

/// 状态栏左侧：当前选中 commit 的短哈希。
///
/// 订阅 `CommitDetailProviding` 观察者事件，选中 commit 变化时
/// 显示对应短哈希（未选中时显示占位）。
struct CommitStatusBarItem: View {
    let detail: any CommitDetailProviding
    @StateObject private var observation: CommitDetailObservationModel

    init(detail: any CommitDetailProviding) {
        self.detail = detail
        _observation = StateObject(wrappedValue: CommitDetailObservationModel(detail: detail))
    }

    var body: some View {
        AppStatusBarTile(systemImage: "arrow.left.arrow.right") {
            Text(detail.selectedCommit?.shortHash ?? "No Commit")
                .lineLimit(1)
        }
    }
}

/// 观察模型：订阅 `CommitDetailProviding` 的观察者事件，
/// 把变化转成 `@Published revision` 以驱动 SwiftUI 视图重算。
@MainActor
final class CommitDetailObservationModel: ObservableObject {
    @Published private(set) var revision = 0
    private var handle: (any CommitDetailObserverHandle)?

    init(detail: any CommitDetailProviding) {
        handle = detail.addObserver { [weak self] _ in
            self?.revision += 1
        }
    }
}
