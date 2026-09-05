import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderActivity
import ProviderStatusBar
import SwiftUI

// MARK: - Activity Status SuperPlugin

/// 活动状态插件
///
/// 在状态栏注册活动指示器：订阅 `ActivityProviding`，当有长时间操作
/// （提交 / 推送等）进行中时，显示 spinner + 活动描述（对齐旧版
/// PluginActivityStatus 的 AppStatusBarTile）。
@MainActor
public final class ActivityStatusPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.activity-status", category: "ActivityStatus")
    nonisolated public static let emoji = "⚙️"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.activity-status"
    public let order = 31
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.activity-status",
        name: "Activity Status",
        description: "Show current long-running activity (commit/push) in the status bar",
        category: .project,
        stage: .stable,
        policy: .disabled
    )

    static let itemID = "com.coffic.gitok.plugin.activity-status.id"

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let statusBar = kernel.resolveProvider((any StatusBarProviding).self) else {
            Self.logger.error("\(self.t)StatusBarProviding not registered; skip activity status item")
            return
        }
        guard let activity = kernel.resolveProvider((any ActivityProviding).self) else {
            Self.logger.error("\(self.t)ActivityProviding not registered; skip activity status item")
            return
        }

        statusBar.addStatusBarItems([
            StatusBarItem(
                id: Self.itemID,
                title: ActivityStatusLocalization.string("Activity", bundle: .module),
                placement: .center,
                order: 5
            ) {
                ActivityStatusTile(activity: activity)
            },
        ])
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any StatusBarProviding).self)?
            .removeStatusBarItems(ids: [Self.itemID])
    }
}
