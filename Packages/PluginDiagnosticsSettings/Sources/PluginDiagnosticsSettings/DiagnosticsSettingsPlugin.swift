import Foundation
import KernelCore
import KitSuperLog
import os
import ProviderSettingView
import SwiftUI

// MARK: - Diagnostics Settings SuperPlugin

/// 诊断设置插件：在设置窗口注册「Diagnostics」入口
/// （对齐旧版 PluginDiagnosticsSettings）。
@MainActor
public final class DiagnosticsSettingsPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.diagnostics-settings", category: "DiagnosticsSettings")
    nonisolated public static let emoji = "🩺"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.diagnostics-settings"
    public let order = 47
    public let dependencies = ["com.coffic.lumi.plugin.setting-view"]
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.diagnostics-settings",
        name: "Diagnostics",
        description: "App diagnostic information and logs",
        category: .system,
        stage: .stable,
        policy: .alwaysOn
    )

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let settings = kernel.resolveProvider((any SettingViewProviding).self) else {
            Self.logger.error("\(self.t)SettingViewProviding not registered; skip diagnostics entry")
            return
        }
        settings.addEntries([
            SettingEntryItem(
                id: "diagnostics",
                title: "Diagnostics",
                systemImage: "stethoscope",
                order: 60
            ) {
                DiagnosticsSettingView()
            },
        ])
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any SettingViewProviding).self)?
            .removeEntries(ids: ["diagnostics"])
    }
}
